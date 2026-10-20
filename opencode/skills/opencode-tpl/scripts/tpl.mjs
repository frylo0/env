#!/usr/bin/env node
/**
 * opencode-tpl — Project Config Template CLI.
 *
 * Self-contained Node CLI (no external deps) that manages OpenCode config templates
 * (provider defaults, etc.) and merges one into a project config.
 *
 * SECRET CONTRACT:
 *  - Only this file touches `tpl/<name>/secrets/`. It never prints secret contents.
 *  - It copies secret files verbatim (fs.copyFileSync) and only logs filenames, never contents.
 *  - It never accepts a secret value from the caller; only a template *name*.
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import readline from 'node:readline';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SKILL_DIR = path.resolve(__dirname, '..');
const TPL_DIR = path.join(SKILL_DIR, 'tpl');

const INDENT = 2;
const NAME_RE = /^[A-Za-z0-9][A-Za-z0-9._-]*$/;

/* ---------------------------------------------------------------- helpers */

function die(msg, code = 1) {
  console.error(msg);
  process.exit(code);
}

function hasOwn(obj, k) {
  return Object.prototype.hasOwnProperty.call(obj, k);
}

function isPlainObject(v) {
  return v !== null && typeof v === 'object' && !Array.isArray(v);
}

function deepEqual(a, b) {
  if (a === b) return true;
  if (typeof a !== typeof b) return false;
  if (a === null || b === null) return false;
  if (typeof a !== 'object') return false;
  if (Array.isArray(a) !== Array.isArray(b)) return false;
  if (Array.isArray(a)) {
    if (a.length !== b.length) return false;
    for (let i = 0; i < a.length; i++) if (!deepEqual(a[i], b[i])) return false;
    return true;
  }
  const ka = Object.keys(a);
  const kb = Object.keys(b);
  if (ka.length !== kb.length) return false;
  for (const k of ka) {
    if (!hasOwn(b, k)) return false;
    if (!deepEqual(a[k], b[k])) return false;
  }
  return true;
}

/** Strip JSONC line + block comments and trailing commas, outside of strings. */
function stripJsonc(src) {
  let out = '';
  let inStr = false;
  const n = src.length;
  let i = 0;
  while (i < n) {
    const c = src[i];
    if (inStr) {
      out += c;
      if (c === '\\') {
        if (i + 1 < n) out += src[i + 1];
        i += 2;
        continue;
      }
      if (c === '"') inStr = false;
      i++;
      continue;
    }
    if (c === '"') {
      inStr = true;
      out += c;
      i++;
      continue;
    }
    if (c === '/' && src[i + 1] === '/') {
      while (i < n && src[i] !== '\n') i++;
      continue;
    }
    if (c === '/' && src[i + 1] === '*') {
      i += 2;
      while (i < n && !(src[i] === '*' && src[i + 1] === '/')) i++;
      i += 2;
      continue;
    }
    if (c === ',') {
      let j = i + 1;
      while (j < n && /\s/.test(src[j])) j++;
      if (src[j] === '}' || src[j] === ']') {
        i++;
        continue;
      }
      out += c;
      i++;
      continue;
    }
    out += c;
    i++;
  }
  return out;
}

function parseJsonc(src) {
  return JSON.parse(stripJsonc(src));
}

function readJsonc(file) {
  if (!fs.existsSync(file)) return null;
  try {
    return parseJsonc(fs.readFileSync(file, 'utf8'));
  } catch (e) {
    die(`Failed to parse JSONC: ${file}\n  ${e.message}`);
  }
}

function writeJsonc(file, obj) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, JSON.stringify(obj, null, INDENT) + '\n', 'utf8');
}

/* --------------------------------------------------------------- merge */

function collectKeys(a, b) {
  const keys = new Set();
  if (isPlainObject(a)) Object.keys(a).forEach((k) => keys.add(k));
  if (isPlainObject(b)) Object.keys(b).forEach((k) => keys.add(k));
  return [...keys];
}

/**
 * Deep-merge `template` into `target` (target = project, wins by default).
 * Objects recurse; scalars/arrays are leaves. Where both sides define a leaf
 * that differs, `onConflict(path, projectVal, templateVal)` is called and its
 * return value is used as the merged leaf value. onConflict may track the
 * conflict for reporting.
 */
function merge(target, template, pathBase, onConflict) {
  const out = {};
  for (const k of collectKeys(target, template)) {
    const p = pathBase ? `${pathBase}.${k}` : String(k);
    const hasT = isPlainObject(target) && hasOwn(target, k);
    const hasM = isPlainObject(template) && hasOwn(template, k);

    if (!hasT) {
      out[k] = template[k];
      continue;
    }
    if (!hasM) {
      out[k] = target[k];
      continue;
    }
    const tv = target[k];
    const mv = template[k];

    if (isPlainObject(tv) && isPlainObject(mv)) {
      out[k] = merge(tv, mv, p, onConflict);
      continue;
    }
    if (deepEqual(tv, mv)) {
      out[k] = tv;
      continue;
    }
    out[k] = onConflict(p, tv, mv);
  }
  return out;
}

function runCheck(tplJson, targetJson) {
  const conflicts = [];
  merge(targetJson, tplJson, '', (p, tv, mv) => {
    conflicts.push({ path: p, project: tv, template: mv });
    return mv;
  });
  for (const c of conflicts) {
    console.log(`${c.path} | project=${JSON.stringify(c.project)} | template=${JSON.stringify(c.template)}`);
  }
  if (conflicts.length) {
    console.error(`\n${conflicts.length} conflict(s) detected.`);
    return 1;
  }
  console.log('No conflicts.');
  return 0;
}

function runApply(tplJson, targetJson, resolveJson) {
  let resolveMap = {};
  if (resolveJson != null && resolveJson.trim() !== '') {
    try {
      resolveMap = JSON.parse(resolveJson);
    } catch (e) {
      die(`--resolve must be valid JSON: ${e.message}`);
    }
  }

  const conflicts = [];
  const unresolved = [];
  const aborted = [];
  const merged = merge(targetJson, tplJson, '', (p, tv, mv) => {
    conflicts.push({ path: p, project: tv, template: mv });
    if (!hasOwn(resolveMap, p)) {
      unresolved.push(p);
      return mv;
    }
    const choice = resolveMap[p];
    if (choice === 'keep') return tv;
    if (choice === 'take') return mv;
    if (choice === 'abort') {
      aborted.push(p);
      return mv;
    }
    die(`Invalid choice "${choice}" for "${p}" (expected keep|take|abort).`);
  });

  if (aborted.length) {
    console.error(`Aborting: 'abort' chosen for: ${aborted.join(', ')}`);
    return 1;
  }
  if (unresolved.length) {
    console.error('Cannot apply: no resolution for conflict(s): ' + unresolved.join(', '));
    console.error('Provide every conflict via --resolve, e.g.:');
    console.error(`  --resolve '${JSON.stringify(Object.fromEntries(conflicts.map((c) => [c.path, 'keep'])))}'`);
    return 1;
  }
  return merged;
}

/* --------------------------------------------------------- template io */

function templateDir(name) {
  if (!PATH_SAFE(name)) die(`Invalid template name: "${name}"`);
  return path.join(TPL_DIR, name);
}
function PATH_SAFE(name) {
  return NAME_RE.test(name) && !name.includes('..');
}

function ensureTemplate(name) {
  const dir = templateDir(name);
  const cfg = path.join(dir, 'opencode.jsonc');
  if (!fs.existsSync(cfg)) die(`Unknown template "${name}" (no opencode.jsonc in ${dir})`);
  return dir;
}

function summaryOf(name) {
  const f = path.join(TPL_DIR, name, 'tpl.md');
  if (!fs.existsSync(f)) return '';
  const lines = fs
    .readFileSync(f, 'utf8')
    .split('\n')
    .map((l) => l.trim())
    .filter((l) => l && !l.startsWith('#'));
  return lines[0] || '';
}

/* ------------------------------------------------------------ commands */

function cmdList() {
  if (!fs.existsSync(TPL_DIR)) {
    console.log('No templates.');
    return;
  }
  const names = fs
    .readdirSync(TPL_DIR)
    .filter((n) => fs.statSync(path.join(TPL_DIR, n)).isDirectory())
    .sort();
  if (!names.length) {
    console.log('No templates.');
    return;
  }
  for (const name of names) {
    const s = summaryOf(name);
    console.log(s ? `${name}: ${s}` : name);
  }
}

function cmdShow(name) {
  const cfg = path.join(ensureTemplate(name), 'opencode.jsonc');
  console.log(fs.readFileSync(cfg, 'utf8'));
}

function cmdAdd(name) {
  if (!PATH_SAFE(name)) die(`Invalid template name: "${name}"`);
  const dir = templateDir(name);
  if (fs.existsSync(dir)) die(`Template "${name}" already exists: ${dir}`);
  fs.mkdirSync(path.join(dir, 'secrets'), { recursive: true });
  fs.writeFileSync(
    path.join(dir, 'opencode.jsonc'),
    JSON.stringify(
      {
        $schema: 'https://opencode.ai/config.json',
        model: 'provider/model',
        providers: {},
      },
      null,
      INDENT,
    ) + '\n',
    'utf8',
  );
  fs.writeFileSync(
    path.join(dir, 'tpl.md'),
    `# ${name}\n\nDescribe what this template provides and how to add its secret file.\n`,
    'utf8',
  );
  console.log(`Created template "${name}" at ${dir}`);
  console.log('Add your secret file(s) under ' + path.join(dir, 'secrets') + ' (never commit them).');
}

function cmdRm(name, yes) {
  const dir = ensureTemplate(name);
  if (!yes) {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
    rl.question(`Really delete template "${name}"? [y/N] `, (ans) => {
      rl.close();
      if (!/^y(es)?$/i.test(ans.trim())) {
        console.log('Aborted.');
        return;
      }
      fs.rmSync(dir, { recursive: true, force: true });
      console.log(`Deleted template "${name}".`);
    });
    return;
  }
  fs.rmSync(dir, { recursive: true, force: true });
  console.log(`Deleted template "${name}".`);
}

/* -------------------------------------------------------- target config */

function resolveTargetConfig(targetArg) {
  const resolved = path.resolve(targetArg);
  if (fs.existsSync(resolved) && fs.statSync(resolved).isFile()) return resolved;
  const cands = [
    path.join(resolved, '.opencode', 'opencode.jsonc'),
    path.join(resolved, 'opencode.jsonc'),
  ];
  for (const c of cands) {
    if (fs.existsSync(c)) return c;
  }
  return path.join(resolved, '.opencode', 'opencode.jsonc');
}

function findGitRoot(start) {
  let dir = start;
  for (;;) {
    if (fs.existsSync(path.join(dir, '.git'))) return dir;
    const parent = path.dirname(dir);
    if (parent === dir) return null;
    dir = parent;
  }
}

function copySecrets(name, configPath) {
  const srcDir = path.join(ensureTemplate(name), 'secrets');
  const destDir = path.dirname(configPath);
  if (!fs.existsSync(srcDir)) {
    console.log('No secrets/ folder in template; nothing to copy.');
    return [];
  }
  const files = fs
    .readdirSync(srcDir)
    .filter((f) => {
      const p = path.join(srcDir, f);
      return fs.statSync(p).isFile();
    })
    .sort();
  if (!files.length) {
    console.log('secrets/ is empty; nothing to copy.');
    return [];
  }
  fs.mkdirSync(destDir, { recursive: true });
  for (const f of files) {
    // Copy bytes only; content is never read/echoed here.
    fs.copyFileSync(path.join(srcDir, f), path.join(destDir, f));
  }
  console.log(`Copied ${files.length} secret file(s) to ${destDir} (${files.join(', ')}).`);
  return files;
}

function updateGitignore(configPath, secretFiles) {
  const destDir = path.dirname(configPath);
  const gitRoot = findGitRoot(destDir);
  if (!gitRoot) {
    console.log('Not inside a git repo; skipping .gitignore update.');
    return;
  }
  const giPath = path.join(gitRoot, '.gitignore');
  const existing = fs.existsSync(giPath) ? fs.readFileSync(giPath, 'utf8') : '';
  const lines = existing.length ? existing.split('\n') : [];
  let added = 0;
  for (const f of secretFiles) {
    const rel = path.relative(gitRoot, path.join(destDir, f)).replace(/\\/g, '/');
    if (rel.startsWith('..')) {
      console.log(`Skip gitignore for ${rel}: outside repo.`);
      continue;
    }
    if (lines.includes(rel)) continue;
    lines.push(rel);
    added++;
  }
  if (added) {
    fs.mkdirSync(gitRoot, { recursive: true });
    // Coalesce trailing blank lines to a single newline before append.
    const base = lines.filter((l, i) => !(l === '' && i === lines.length - 1));
    fs.writeFileSync(giPath, base.join('\n') + '\n', 'utf8');
    console.log(`Appended ${added} path(s) to ${giPath}.`);
  } else {
    console.log('Gitignore already up to date.');
  }
}

function cmdApply(name, targetArg, resolveJson, dry) {
  const cfgFile = resolveTargetConfig(targetArg);
  const tplDir = ensureTemplate(name);
  const tplJson = readJsonc(path.join(tplDir, 'opencode.jsonc'));
  const targetJson = readJsonc(cfgFile) || {};

  // Detect conflicts first (reports them, but does not write).
  const conflicts = [];
  merge(targetJson, tplJson, '', (p, tv, mv) => {
    conflicts.push({ path: p, project: tv, template: mv });
    return mv;
  });

  // With unknown conflicts and no --resolve, stop and ask the caller for choices.
  if (conflicts.length && resolveJson == null) {
    for (const c of conflicts) {
      console.log(`${c.path} | project=${JSON.stringify(c.project)} | template=${JSON.stringify(c.template)}`);
    }
    console.error(`\n${conflicts.length} conflict(s). Resolve with: tpl.mjs apply ${name} ${targetArg} --resolve '<map>'`);
    return 1;
  }

  const merged = runApply(tplJson, targetJson, resolveJson || '{}');
  if (typeof merged === 'number') return merged;

  if (dry) {
    console.log('DRY-RUN. Would write: ' + cfgFile);
    return 0;
  }
  writeJsonc(cfgFile, merged);
  console.log(`Wrote merged config to ${cfgFile}`);
  const copied = copySecrets(name, cfgFile);
  if (copied.length) updateGitignore(cfgFile, copied);
  return 0;
}

/* -------------------------------------------------------------- main */

function usage() {
  console.log(`opencode-tpl — project config template CLI

Usage:
  tpl.mjs list
  tpl.mjs show <name>
  tpl.mjs add <name>
  tpl.mjs rm <name> [--yes]
  tpl.mjs merge --check <name> <target>
  tpl.mjs merge --apply <name> <target> --resolve '<json path→choice map>'
  tpl.mjs sync <name> <target> [--resolve '<json path→choice map>']
  tpl.mjs apply <name> <target> [--resolve '<json path→choice map>']

<target> is a directory (e.g. ".") or a config file. If a directory, the config
is resolved as: .opencode/opencode.jsonc → opencode.jsonc → create .opencode/opencode.jsonc.

Conflict choices: "keep" (project wins) | "take" (template wins) | "abort".
`);
}

function main() {
  const argv = process.argv.slice(2);
  const cmd = argv[0];
  if (!cmd || cmd === '--help' || cmd === '-h' || cmd === 'help') {
    usage();
    return;
  }

  if (cmd === 'list') return cmdList();
  if (cmd === 'show') {
    if (!argv[1]) die('Usage: tpl.mjs show <name>');
    return cmdShow(argv[1]);
  }
  if (cmd === 'add') {
    if (!argv[1]) die('Usage: tpl.mjs add <name>');
    return cmdAdd(argv[1]);
  }
  if (cmd === 'rm') {
    if (!argv[1]) die("Usage: tpl.mjs rm <name> [--yes]");
    const yes = argv.includes('--yes') || argv.includes('-y') || argv.includes('--force');
    return cmdRm(argv[1], yes);
  }
  if (cmd === 'merge') {
    const flag = argv[1];
    const name = argv[2];
    const target = argv[3];
    if ((flag !== '--check' && flag !== '--apply') || !name || !target) {
      die('Usage: tpl.mjs merge --check|--apply <name> <target> [--resolve <json>]');
    }
    const tplJson = readJsonc(path.join(ensureTemplate(name), 'opencode.jsonc'));
    const targetJson = readJsonc(resolveTargetConfig(target)) || {};
    if (flag === '--check') return runCheck(tplJson, targetJson);
    const resolveIdx = argv.indexOf('--resolve');
    const resolveJson = resolveIdx >= 0 ? argv[resolveIdx + 1] : null;
    const merged = runApply(tplJson, targetJson, resolveJson);
    if (typeof merged === 'number') return merged;
    const outFile = resolveTargetConfig(target);
    writeJsonc(outFile, merged);
    console.log(`Wrote merged config to ${outFile}`);
    return 0;
  }
  if (cmd === 'sync') {
    const name = argv[1];
    const target = argv[2];
    if (!name || !target) die("Usage: tpl.mjs sync <name> <target> [--resolve '<json path→choice map>']");
    const tplJson = readJsonc(path.join(ensureTemplate(name), 'opencode.jsonc'));
    const outFile = resolveTargetConfig(target);
    const targetJson = readJsonc(outFile) || {};
    const resolveIdx = argv.indexOf('--resolve');
    const resolveJson = resolveIdx >= 0 ? argv[resolveIdx + 1] : null;
    const merged = runApply(tplJson, targetJson, resolveJson);
    if (typeof merged === 'number') return merged;
    writeJsonc(outFile, merged);
    console.log(`Synced template "${name}" to ${outFile}`);
    return 0;
  }
  if (cmd === 'apply') {
    const name = argv[1];
    const target = argv[2];
    if (!name || !target) die('Usage: tpl.mjs apply <name> <target> [--resolve <json>]');
    const resolveIdx = argv.indexOf('--resolve');
    const resolveJson = resolveIdx >= 0 ? argv[resolveIdx + 1] : null;
    const dry = argv.includes('--dry-run') || argv.includes('-n');
    return cmdApply(name, target, resolveJson, dry);
  }

  die(`Unknown command: "${cmd}"\n`);
}

const rc = main();
if (typeof rc === 'number') process.exitCode = rc;
if (process.exitCode == null) process.exitCode = 0;
