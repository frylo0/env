import { appendFile, mkdir, open } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"

const TOKEN_ENV = "NTFY_TOKEN"
const REQUEST_TIMEOUT_MS = 10_000
const DIAGNOSTIC_LOG = join(tmpdir(), "opencode-ntfy-debug.log")
const CLAIM_DIRECTORY = join(tmpdir(), "opencode-ntfy-event-claims")

const DEFAULT_CONFIG = {
  server: "https://ntfy.frylo.org",
  messages: {
    done: "✅ done",
    ask: "💬 ask",
    perm: "🔐 perm",
  },
}

const NOTIFICATION_KINDS = new Set(["done", "ask", "perm"])

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value)
}

function resolveConfig(options) {
  const settings = isRecord(options) ? options : {}
  const configuredMessages = isRecord(settings.messages) ? settings.messages : {}

  return {
    server: settings.server ?? DEFAULT_CONFIG.server,
    topic: settings.topic,
    tokenEnv: settings.tokenEnv,
    messages: { ...DEFAULT_CONFIG.messages, ...configuredMessages },
  }
}

export function notificationUrl(server, topic) {
  if (typeof server !== "string" || typeof topic !== "string" || !topic.trim()) {
    throw new Error("ntfy server and topic are required")
  }

  let url
  try {
    url = new URL(server)
  } catch {
    throw new Error("invalid server URL; include https:// or http://")
  }
  if (url.protocol !== "http:" && url.protocol !== "https:") {
    throw new Error("ntfy server must use HTTP or HTTPS")
  }

  const basePath = url.pathname.replace(/\/+$/, "")
  url.pathname = `${basePath}/${encodeURIComponent(topic.trim())}`
  url.search = ""
  url.hash = ""
  return url
}

function authorizationHeader(config, env) {
  const token = env[config.tokenEnv || TOKEN_ENV]
  return token ? { Authorization: `Bearer ${token}` } : {}
}

function networkErrorCode(error) {
  const code = error?.cause?.code ?? error?.code
  return typeof code === "string" ? code : error?.name
}

function createSender({ config, url, env, fetchImpl, isDisposed, info, reportError }) {
  return async function sendNotification(kind) {
    const body = config.messages[kind]
    if (isDisposed()) {
      info(`notification skipped (${kind}): plugin is shutting down`)
      return
    }
    if (!NOTIFICATION_KINDS.has(kind) || typeof body !== "string") {
      info(`notification skipped (${kind}): invalid kind or message`)
      return
    }

    try {
      info(`sending ${kind} notification to ${url.origin}`)
      const response = await fetchImpl(url, {
        method: "POST",
        headers: {
          "Content-Type": "text/plain; charset=utf-8",
          ...authorizationHeader(config, env),
        },
        body,
        signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
      })

      if (!response.ok) {
        reportError(`ntfy server ${url.origin} rejected a notification`, `HTTP ${response.status}${response.statusText ? ` ${response.statusText}` : ""}`)
        info(`${kind} notification rejected with HTTP ${response.status}`)
      } else {
        info(`${kind} notification accepted with HTTP ${response.status}`)
      }
    } catch (error) {
      reportError(`could not reach ntfy server ${url.origin}`, networkErrorCode(error))
      info(`${kind} notification request failed`)
    }
  }
}

function eventData(event) {
  return event?.data ?? event?.properties ?? {}
}

async function claimEvent(eventID, reportError) {
  if (typeof eventID !== "string" || !eventID) {
    reportError("cannot deduplicate event", "v2 event has no ID")
    return false
  }

  try {
    await mkdir(CLAIM_DIRECTORY, { recursive: true, mode: 0o700 })
    const marker = join(CLAIM_DIRECTORY, `${encodeURIComponent(eventID)}.claimed`)
    const handle = await open(marker, "wx", 0o600)
    await handle.close()
    return true
  } catch (error) {
    if (error?.code === "EEXIST") return false
    reportError("could not claim event for deduplication", networkErrorCode(error))
    return false
  }
}

function createEventHandler({ getSession, sendNotification, info, reportError }) {
  async function notifyCompletion(sessionID, eventID) {
    if (typeof sessionID !== "string") {
      info("completion ignored: event has no session ID")
      return
    }
    const primary = await getSession(sessionID)
    info(`completion session lookup: ${primary ? "primary" : "not primary or lookup failed"}`)
    if (!primary) {
      info("completion ignored because the session is not confirmed as primary")
      return
    }

    if (!await claimEvent(eventID, reportError)) {
      info("duplicate completion ignored")
      return
    }

    info("completion accepted for primary session")
    await sendNotification("done")
  }

  return async function handleEvent(input) {
    const event = input?.event ?? input
    info(`received event ${event?.type ?? "<unknown>"}`)
    const data = eventData(event)

    if (event?.type === "permission.v2.asked" || event?.type === "permission.asked") {
      if (!await claimEvent(event.id, reportError)) {
        info("duplicate permission event ignored")
        return
      }
      info("permission event matched perm notification")
      await sendNotification("perm")
      return
    }

    if (event?.type === "question.v2.asked" || event?.type === "question.asked") {
      if (!await claimEvent(event.id, reportError)) {
        info("duplicate question event ignored")
        return
      }
      info("question event matched ask notification")
      await sendNotification("ask")
      return
    }

    if (event?.type === "form.created" && data.form?.metadata?.kind === "question") {
      if (!await claimEvent(event.id, reportError)) {
        info("duplicate question form ignored")
        return
      }
      info("question form matched ask notification")
      await sendNotification("ask")
      return
    }

    if ([
      "session.execution.succeeded",
      "session.execution.failed",
      "session.execution.interrupted",
    ].includes(event?.type)) {
      info(`terminal execution event observed (${event.type})`)
      await notifyCompletion(data.sessionID, event.id)
    }
  }
}

function createRuntime({ options, env, fetchImpl, writeLog }) {
  const config = resolveConfig(options)
  const info = (message) => writeLog("info", `[opencode-ntfy:lifecycle] ${message}`)
  const reportError = (message, details) => writeLog("error", `[opencode-ntfy] ${message}${details ? ` (${details})` : ""}`)
  info(`configuration received; topic ${typeof config.topic === "string" && config.topic.trim() ? "present" : "missing"}`)

  if (typeof config.topic !== "string" || !config.topic.trim()) {
    reportError("plugin is disabled", "set a project-specific topic in the plugin options")
    info("setup stopped because required configuration is missing")
    return
  }

  let url
  try {
    url = notificationUrl(config.server, config.topic)
  } catch (error) {
    reportError("invalid configuration", error.message)
    info("setup stopped because server configuration is invalid")
    return
  }
  if (url.protocol === "http:") {
    writeLog("warn", `[opencode-ntfy] server ${url.origin} uses unencrypted HTTP`)
  }
  info(`configuration validated for server ${url.origin}`)

  let disposed = false
  const sendNotification = createSender({
    config,
    url,
    env,
    fetchImpl,
    isDisposed: () => disposed,
    info,
    reportError,
  })

  info("runtime initialized")
  return {
    sendNotification,
    dispose: () => {
      disposed = true
      info("runtime disposed")
    },
    info,
    reportError,
  }
}

async function setupV2(context) {
  // Temporary INFO-level lifecycle tracing; remove after diagnosing deployment.
  const writeLog = (level, message) => {
    const line = `${new Date().toISOString()} level=${level.toUpperCase()} ${message}\n`
    void appendFile(DIAGNOSTIC_LOG, line, { mode: 0o600 }).catch((error) => {
      console.error(`[opencode-ntfy] could not write diagnostic file: ${networkErrorCode(error)}`)
    })

    try {
      const result = context.app.log({ service: "opencode-ntfy", level, message })
      result?.catch((error) => console.error(`[opencode-ntfy] could not write diagnostic log: ${networkErrorCode(error)}`))
    } catch (error) {
      console.error(`[opencode-ntfy] could not write diagnostic log: ${networkErrorCode(error)}`)
    }
  }

  writeLog("info", `[opencode-ntfy:lifecycle] setup entered at ${context.location.directory}`)
  const runtime = await createRuntime({
    options: context.options,
    env: process.env,
    fetchImpl: fetch,
    writeLog,
  })
  if (!runtime) {
    writeLog("info", "[opencode-ntfy:lifecycle] setup exited without runtime")
    return
  }

  const controller = new AbortController()
  runtime.info("event subscription starting")
  const handleEvent = createEventHandler({
    getSession: async (sessionID) => {
      try {
        const session = await context.session.get({ sessionID })
        const primary = Boolean(session && !session.parentID)
        runtime.info(`session lookup completed: ${primary ? "primary" : "child or missing"}`)
        return primary
      } catch (error) {
        runtime.reportError("could not verify whether the completed session is primary", networkErrorCode(error))
        return false
      }
    },
    sendNotification: runtime.sendNotification,
    info: runtime.info,
    reportError: runtime.reportError,
  })

  const subscriptionTask = (async () => {
    try {
      for await (const event of context.event.subscribe({ signal: controller.signal })) {
        await handleEvent(event)
      }
      if (!controller.signal.aborted) runtime.info("event subscription ended")
    } catch (error) {
      if (!controller.signal.aborted) runtime.reportError("event subscription failed", networkErrorCode(error))
    }
  })()

  return async () => {
    runtime.info("cleanup started")
    controller.abort()
    await subscriptionTask
    runtime.dispose()
    runtime.info("cleanup finished")
  }
}

const plugin = {
  id: "opencode-ntfy",
  setup: setupV2,
}

export default plugin
