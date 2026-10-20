import test from "node:test"
import assert from "node:assert/strict"
import plugin, { notificationUrl } from "./index.js"

const config = {
  topic: "project topic",
  server: "https://ntfy.example",
  messages: { done: "D", ask: "A", perm: "P" },
}

function makeContext({ options = config, events = [], childSessions = [], directory = "/project" } = {}) {
  const logs = []
  const notifications = []
  return {
    logs,
    notifications,
    context: {
      options,
      location: { directory },
      app: { log: async (entry) => logs.push(entry) },
      session: {
        get: async ({ sessionID }) => ({ parentID: childSessions.includes(sessionID) ? "parent" : undefined }),
      },
      event: { subscribe: async function* () { yield* events } },
    },
  }
}

async function withFetch(fetchMock, run) {
  const originalFetch = globalThis.fetch
  globalThis.fetch = fetchMock
  try {
    return await run()
  } finally {
    globalThis.fetch = originalFetch
  }
}

let nextEventID = 0
const event = (type, data = {}) => ({
  id: `evt_test_${++nextEventID}`,
  type,
  data,
  location: { directory: "/project" },
})

test("exports a v2 plugin definition", () => {
  assert.equal(plugin.id, "opencode-ntfy")
  assert.equal(typeof plugin.setup, "function")
  assert.equal("server" in plugin, false)
})

test("encodes topic and retains server path", () => {
  assert.equal(notificationUrl("https://ntfy.example/base/", "my topic").href, "https://ntfy.example/base/my%20topic")
})

test("routes v2 question and permission events to distinct messages", async () => {
  const harness = makeContext({
    events: [
      event("question.v2.asked"),
      event("permission.v2.asked"),
      event("session.idle", { sessionID: "primary" }),
    ],
  })
  await withFetch(async (_, request) => {
    harness.notifications.push(request.body)
    return { ok: true, status: 200 }
  }, async () => {
    const cleanup = await plugin.setup(harness.context)
    await new Promise((resolve) => setImmediate(resolve))
    cleanup()
  })
  assert.deepEqual(harness.notifications, ["A", "P"])
})

test("uses v2 terminal execution events and notifies primary sessions only once", async () => {
  const harness = makeContext({
    childSessions: ["child"],
    events: [
      event("session.execution.succeeded", { sessionID: "child" }),
      event("session.execution.succeeded", { sessionID: "primary" }),
    ],
  })
  harness.context.event.subscribe = async function* () {
    const execution = event("session.execution.succeeded", { sessionID: "primary" })
    yield execution
    yield execution
  }
  await withFetch(async (_, request) => {
    harness.notifications.push(request.body)
    return { ok: true, status: 200 }
  }, async () => {
    const cleanup = await plugin.setup(harness.context)
    await new Promise((resolve) => setImmediate(resolve))
    cleanup()
  })
  assert.deepEqual(harness.notifications, ["D"])
})

test("only the plugin instance matching the event location sends", async () => {
  const completion = event("session.execution.succeeded", { sessionID: "primary" })
  completion.location.workspaceID = "event-workspace"
  const outside = makeContext({ directory: "/other", events: [completion] })
  const matching = makeContext({ directory: "/project", events: [completion] })
  await withFetch(async (_, request) => {
    matching.notifications.push(request.body)
    return { ok: true, status: 200 }
  }, async () => {
    const disposeOutside = await plugin.setup(outside.context)
    const disposeMatching = await plugin.setup(matching.context)
    await new Promise((resolve) => setImmediate(resolve))
    disposeOutside()
    disposeMatching()
  })
  assert.deepEqual(outside.notifications, [])
  assert.deepEqual(matching.notifications, ["D"])
})

test("uses token from environment and reports request failures", async () => {
  const harness = makeContext({ events: [event("question.v2.asked")] })
  const originalToken = process.env.NTFY_TOKEN
  process.env.NTFY_TOKEN = "secret"
  await withFetch(async (_, request) => {
    assert.equal(request.headers.Authorization, "Bearer secret")
    throw Object.assign(new Error("offline"), { cause: { code: "ECONNREFUSED" } })
  }, async () => {
    const cleanup = await plugin.setup(harness.context)
    await new Promise((resolve) => setImmediate(resolve))
    cleanup()
  })
  if (originalToken === undefined) delete process.env.NTFY_TOKEN
  else process.env.NTFY_TOKEN = originalToken
  assert.ok(harness.logs.some((entry) => entry.level === "error" && entry.message.includes("ECONNREFUSED")))
  assert.ok(harness.logs.every((entry) => !entry.message.includes("secret")))
})

test("reports invalid URL and HTTP response errors", async () => {
  const invalid = makeContext({ options: { ...config, server: "ntfy.example" } })
  const noEvents = []
  invalid.context.event.subscribe = async function* () { yield* noEvents }
  const stopInvalid = await plugin.setup(invalid.context)
  assert.ok(invalid.logs.some((entry) => entry.message.includes("include https:// or http://")))
  stopInvalid?.()

  const failedResponse = makeContext({ events: [event("question.v2.asked")] })
  await withFetch(async () => ({ ok: false, status: 401, statusText: "Unauthorized" }), async () => {
    const cleanup = await plugin.setup(failedResponse.context)
    await new Promise((resolve) => setImmediate(resolve))
    cleanup()
  })
  assert.ok(failedResponse.logs.some((entry) => entry.message.includes("HTTP 401 Unauthorized")))
})

test("lifecycle info logs event and delivery path without topic or message", async () => {
  const harness = makeContext({ options: { ...config, topic: "private-topic" }, events: [event("question.v2.asked")] })
  await withFetch(async () => ({ ok: true, status: 200 }), async () => {
    const cleanup = await plugin.setup(harness.context)
    await new Promise((resolve) => setImmediate(resolve))
    cleanup()
  })
  const output = harness.logs.map((entry) => entry.message).join("\n")
  assert.match(output, /runtime initialized/)
  assert.match(output, /received event question\.v2\.asked/)
  assert.match(output, /ask notification accepted with HTTP 200/)
  assert.doesNotMatch(output, /private-topic|\bA\b/)
})
