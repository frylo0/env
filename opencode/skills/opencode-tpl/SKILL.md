---
name: opencode-tpl
description: Apply, merge, and manage project OpenCode config templates (e.g. the RWB provider)
metadata:
  opencode/autoinvoke: false
---

# opencode-tpl — project config template skill

Apply a stored OpenCode config template (a provider + a default model) into a
project's OpenCode config, merging it with any existing config and asking the
user how to resolve conflicts. The API token is never handled by the LLM: it is
kept in the template's `secrets/` folder and copied by a script, never read or
printed by the agent.

## Files

Everything is under this skill directory (`opencode/skills/opencode-tpl`, which is
the live global config when `opencode/` is linked to `~/.config/opencode`).

- `SKILL.md` — this file (orchestration only).
- `scripts/tpl.mjs` — the CLI. No dependencies; run with `node`.
- `tpl/<name>/opencode.jsonc` — a committed template (no secrets).
- `tpl/<name>/tpl.md` — human-readable description of what the template provides.
- `tpl/<name>/secrets/*` — gitignored secrets; **only `tpl.mjs` reads these.**

## SECURITY RULE — never read or echo secrets

- **Never** read `tpl/*/secrets/` and **never** touch any path containing `secrets`
  with `read`, `glob`, `grep`, `write`, or `edit`. (Global permissions deny these.)
- **Never** use a shell command that reads or prints the token. Only `tpl.mjs`
  reads the `secrets/` folder, and it never prints file contents — it only copies
  them and reports filenames/counts.
- **Never** pass a token value to the script. You may only pass a template *name*.
- If a user pastes a token in chat, do **not** write it into a committed file or
  echo it; write it into `tpl/<name>/secrets/<file>` via the shell (the gitignore
  covers it) or point them to `tpl.md`.

Run the CLI from anywhere. The script path is `scripts/tpl.mjs` inside this skill
directory (e.g. `~/.config/opencode/skills/opencode-tpl/scripts/tpl.mjs`, or
`opencode/skills/opencode-tpl/scripts/tpl.mjs` in the dotfiles repo). Example,
from a project root:

```sh
node "$HOME/.config/opencode/skills/opencode-tpl/scripts/tpl.mjs" list
```

## Commands

```text
list                         enumerate templates (name + summary from tpl.md)
show <name>                  print a template's opencode.jsonc
add <name>                   scaffold tpl/<name>/ (config + tpl.md + empty secrets/)
rm <name> [--yes]            delete a template (asks for confirmation unless --yes)
merge --check <name> <target>  report conflicts; exit 1 if any
merge --apply <name> <target> --resolve '<path->choice map>'
                               write the merged config, resolving conflicts
sync <name> <target> [--resolve '<path->choice map>']
                               update an existing project from a changed template
apply <name> <target> [--resolve '<path->choice map>']
                               merge, then copy secrets/ into target config dir's secrets/
                               and gitignore the token files (see below)
push <name> <target>           promote a project's config and secrets/ to the template
```

`<target>` is a project directory (use `.` for the current repo) or a config file.
For a directory the config is resolved as `.opencode/opencode.jsonc` →
`opencode.jsonc` → create `.opencode/opencode.jsonc` if neither exists.

Conflict choices per path: `keep` (project wins), `take` (template wins), `abort`.

## Syncing an updated template

Use `sync <name> <target>` when the stored template has changed and you want to
bring an existing project's config up to date. It uses the same deep-merge and
conflict resolution as `merge --apply`: template keys missing from the project
are added, project-only keys are retained, and differing values require an
explicit choice. Unlike `apply`, `sync` does not copy secrets or modify `.gitignore`.

## Applying a template

1. Run `list` to see available templates (`rwb` is present).
2. Optionally `show <name>` to inspect it. **Do not `show`/open anything under `secrets/`.**
3. Run `apply <name> <target>` (e.g. `apply rwb .`).
   - If the template config and the project config conflict, `tpl.mjs` prints each
     conflict as `path | project=... | template=...` and exits non-zero.
   - For **each** conflict, ask the user: `keep` / `take` / `abort`.
   - Re-run with a resolution map, e.g.:
     `apply <name> <target> --resolve '{"providers.RWB.options.baseURL":"keep","model":"take"}'`
     `--dry-run` / `-n` previews the write without touching files.
4. `apply` then copies `tpl/<name>/secrets/` into a `secrets/` directory beside
   the target config, preserving nested folders and file bytes, and appends each
   copied secret path to the repo's `.gitignore` when inside a git repo. It never
   prints the secret. The destination `secrets/` directory is created even when
   the template's directory is empty.

If you only want to write the config yourself and handle secrets separately, use
`merge --check` / `merge --apply` and confirm the secret copy step.

## Managing templates

- `add <name>` scaffolds a new template; fill in `opencode.jsonc`, edit `tpl.md`,
  then put the secret file(s) into `tpl/<name>/secrets/`.
- `rm <name>` deletes a template after confirmation (pass `--yes` when the user
  already confirmed).
- `push <name> <target>` promotes the target repo's config to the named template
  and copies its adjacent `secrets/` directory into the template's `secrets/`.
  The template secrets directory is always kept present; if the source has no
  `secrets/`, existing template secrets are left unchanged. Secret bytes are
  copied by the CLI only and never printed. This updates the shared template,
  so confirm with the user before running it.
- Template `opencode.jsonc` files are committed; anything under `secrets/` is not.
