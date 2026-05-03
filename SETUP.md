# Apply project defaults

This file is a prompt for Claude Code. Drop into a target repo and say:

> Read SETUP.md from <https://github.com/alexmensch/project-defaults> and apply the defaults to this repo.

Or copy this file into the target repo and say "follow SETUP.md".

The repo at <https://github.com/alexmensch/project-defaults> is the source of
truth for these templates. Read the referenced files directly from there — do
not assume their contents from this prompt. If the repo is checked out
locally, prefer reading from disk.

---

## Before you start

Confirm with the user (one batched question, not one-by-one):

1. **Project type** — Eleventy site / Node library / generic? (Affects which
   lint configs apply and what scripts go into `package.json`.)
2. **Beads (`bd`) for issue tracking?** — If yes: adds `.claude/settings.json`
   hooks, runs `bd init`, appends bd integration block to `CLAUDE.md`/`AGENTS.md`.
3. **Git LFS for binary files?** — If yes: install LFS hooks, copy
   `git/gitattributes.template` to `.gitattributes` and tweak.
4. **GitHub branch protections?** — If yes: import via `gh` after pushing.

Default if user says "just do the standard thing": Eleventy-style + bd + LFS
+ branch protections.

If the target repo isn't a git repo yet, run `git init -b master` first.

## Steps

Apply in order. Skip anything the user opted out of.

### 1. Lint and format configs

Copy from the `lint/` directory of project-defaults to the target repo root:

- `.prettierrc`
- `.prettierignore`
- `.markdownlint-cli2.jsonc`
- `.stylelintrc.json` (CSS/SCSS projects only)
- `eslint.config.js` (JS projects only)

Merge `lint/package.json.partial` into the target's `package.json`:
- Add the listed `scripts` entries (don't overwrite existing keys without
  asking — show the user the diff first).
- Add the listed `devDependencies`.

Don't run `pnpm install` yet — batch with husky in step 3.

### 2. `.gitignore` and `.gitattributes`

- Merge entries from `git/gitignore.template` into the target's `.gitignore`.
  Don't duplicate existing lines; sort sections sensibly.
- If LFS opted in: copy `git/gitattributes.template` to `.gitattributes` at
  repo root. Show user the patterns and ask which to keep.

### 3. Husky (if `package.json` exists)

```bash
pnpm add -D husky
pnpm pkg set scripts.prepare=husky
pnpm install                  # triggers prepare → husky init
```

Then copy `husky/pre-commit` and `husky/pre-push` from project-defaults into
the target's `.husky/` (overwriting the husky-generated stubs).

### 4. Claude Code config (`.claude/settings.json`)

Copy `claude/settings.json` from project-defaults to the target's
`.claude/settings.json`.

The template contains:
- `SessionStart` and `PreCompact` hooks running `bd prime` (only if bd is in
  use — strip both arrays if not)
- `PreToolUse` hook denying `Write`/`Edit` on `*/.claude/projects/*/memory/*.md`
  (always keep this one — it enforces "use bd memories, not MEMORY.md files"
  policy, which applies even in non-bd projects since it just blocks one
  user-level cache directory)

### 5. `CLAUDE.md` (and `AGENTS.md` if appropriate)

If absent, copy `claude/CLAUDE.md.template` to repo root as `CLAUDE.md`. Fill
in the placeholders (`{{PROJECT_NAME}}`, `{{BUILD_COMMAND}}`, etc.) by reading
the target's `package.json` and source layout.

For bd-enabled projects: after `bd init` (step 6), run
`bd hooks integrate --target=CLAUDE.md` (or whichever variant the bd CLI
exposes — check `bd hooks --help` first) to append the bd integration block.
Repeat for `AGENTS.md` if the user wants one.

### 6. Beads (if opted in)

```bash
bd init                       # creates .beads/ with embedded Dolt
bd hooks install              # installs git hooks into .git/hooks/
```

The hooks are installed into `.git/hooks/`, not `.husky/`, so they don't
collide with husky. Verify with `ls .git/hooks/`.

`.beads/`, `*.db`, and `.dolt/` should already be in `.gitignore` from step 2.

Then seed the default cross-project memories. Open
`beads/default-memories.md` from project-defaults and run the
`bd remember` block from there in the target repo. These are
project-agnostic versions of memories that have proven useful across
projects (concurrent-session etiquette, doc-update timing, bd authoring
discipline, commit granularity, bd persistence, etc.). Confirm with
`bd memories` after.

The seeded bodies are deliberately generic — they should be rewritten in
place via `bd remember --key <key> ...` as the project's actual paths,
build commands, and doc layout become known.

### 7. GitHub (FUNDING + branch protections)

- Copy `github/.github/FUNDING.yml` into the target's `.github/FUNDING.yml`.
- For master branch protections: edit
  `github/master-branch-protections.json` to set `source` to the target repo
  (`<owner>/<repo>`) and `id` to `null` (so GitHub assigns a new one), then:

```bash
gh api repos/<owner>/<repo>/rulesets --method POST \
  --input github/master-branch-protections.json
```

Do this only after the first push so the repo exists on GitHub.

### 8. Git config

Don't edit per-repo git config unless the user has a reason (e.g. a repo-specific
signing key). The settings in `git/git-config` are intended for `~/.gitconfig`
and should already be in place globally. Show the file to the user and ask if
they want anything copied per-repo.

### 9. First commit

```bash
git add -A
git status                    # show user what's staged
# user confirms, then:
git commit -m "Initial setup with personal defaults"
git push -u origin master     # or main
```

For bd projects, run `bd dolt push` if a Dolt remote is configured (it usually
isn't — `git push` propagates `.beads/issues.jsonl` which is the source of
truth).

## Things to NOT do

- Don't copy `editors/Preferences.sublime-settings` — that's a user-level
  Sublime Text setting, not a per-repo config.
- Don't run `git config --global` from this flow — those settings should
  already be set; doing so silently from a setup script is too invasive.
- Don't write a project README from a template — every project has different
  framing. Leave `README.md` for the user.
- Don't add CI workflows. They're project-specific.

## When something differs from these defaults

If the target repo already has a different config (e.g. a different prettier
style), show the user the diff and ask which to keep. Don't silently overwrite.
