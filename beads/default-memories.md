# Default beads memories

A starter set of `bd remember` memories that have proven useful across
projects. SETUP.md seeds these after `bd init`.

These are generic — they make no assumptions about the stack, build tool,
or directory layout. After seeding, the user (or a future Claude session)
should adapt them in place via `bd remember --key <key> ...` as project
specifics emerge: stale generic phrasing should be rewritten to point at
the actual paths, commands, and policies of the project.

## How to seed

Run from the project root after `bd init`. Each memory is its own
heredoc-fed `bd remember` call so the multi-paragraph bodies survive
verbatim.

```bash
bd remember --key concurrent-claude-sessions "$(cat <<'EOF'
Concurrent Claude sessions: bd issues marked in_progress with matching uncommitted edits in the worktree usually indicate another live session is working on that bead. Do NOT pick it up, run quality gates against it, stage/commit/push, or close the bead. Confirm with the user first. The 'Status: in_progress' field is the canonical 'someone else has this' signal — git branch ownership alone is not enough because branches are shared across sessions.
EOF
)"

bd remember --key web-access-loops "$(cat <<'EOF'
Don't loop on failed web fetches. If a URL access fails (404, blocked, auth wall, AI-scraper filter, etc.), do NOT keep trying alternative transports (WebFetch -> curl -> different URL -> etc.) in a loop.

Why: the user flagged this explicitly — they don't want time and tokens burned on transport attempts that aren't converging. It's faster for them to grab it manually than to thrash.

How to apply: on the first failure, try one alternative. On the second failure, stop and ask the user to fetch the content themselves and paste it in (or drop the file into the repo, or give the information directly). Tell them the exact URL being attempted so they can fetch it with minimal context-switching.
EOF
)"

bd remember --key bd-create-deps-direction-trap "$(cat <<'EOF'
bd create --deps='blocks:OTHER' direction trap: --deps='blocks:X' on bd create makes the NEW issue block X, not the other way around — opposite of what 'depends' usually means. Workarounds: (1) use plain id with no prefix in --deps (the 'or id' form treats it as 'this issue depends on'), or (2) skip --deps and run 'bd dep <blocker> --blocks <blocked>' after creation. Always verify direction with 'bd dep list <new-issue>' and 'bd ready' immediately after.
EOF
)"

bd remember --key defer-doc-updates "$(cat <<'EOF'
Defer doc updates until the final commit. Don't edit CLAUDE.md, README.md, or anything under docs/ while implementing a change — treat code changes as the only deliverable until commit time.

Why: mid-session doc edits become churn — direction shifts, features get dropped, parameters rename, knob values move; the paragraph written early ends up describing something that no longer exists.

How to apply: during implementation confine edits to code, templates, styles, tests; if a code comment references a doc section about to be wrong, leave it and surface at commit time. At commit time, grep the final diff for renames, removed knobs, new behaviour, anything user-visible — open CLAUDE.md, README.md, docs/ and update only what's now stale. Skip ones that don't need changes.
EOF
)"

bd remember --key bd-authoring "$(cat <<'EOF'
How to author and maintain bd content well across sessions.

(1) Prefer formal bd dep links over prose cross-references whenever the relationship affects planning, ordering, or future work decisions. Alex plans from the dependency graph (bd ready, bd dep list, bd show) — prose 'see issue X' references don't surface there and are easy to miss. Use 'bd dep add' for blocks, the relate variant for relates_to, --parent for parent-child. After filing a batch of issues, audit own descriptions for cross-reference prose and convert each to a formal link before declaring done. Use 'relate' for cross-epic connections (bd's blocks between epics often errors). Avoid epic-level blocks when task-level deps can express the same constraint, since open parents with inbound blockers cause bd ready to cascade-block all children.

(2) When you notice a bd memory is stale, deficient, or contradicts current repo state, update it via 'bd remember --key <existing-key> ...' immediately rather than just noting it in chat. Why: Alex wants memories actively maintained — drift compounds across sessions if corrections aren't written back, and the next session reads the stale version. How to apply: when reading a memory whose specifics don't match current code/config (referenced file no longer exists, flag renamed, policy changed, commit hash referenced is gone, etc.), re-author the memory body in place. Rewrite the whole body each time so it stays self-contained; fragmented amendments are hard to read. Same applies to memories about commands, paths, and project structure.
EOF
)"

bd remember --key commit-granularity "$(cat <<'EOF'
Prefer small topical commits: when a change touches multiple concerns, split them into separate commits each with a focused subject line and brief why-body.

Why: one-concept-per-commit keeps the repo's story legible and makes revert/bisect surgical.

How to apply: when there are unrelated staged changes, don't reach for one omnibus commit message — stage and commit each concern separately. Err toward more commits, not fewer. Keep using HEREDOC commit format with the Co-Authored-By: Claude trailer.
EOF
)"

bd remember --key bd-persistence "$(cat <<'EOF'
How bd state persists — two related operational facts:

(1) bd state is shared across all git worktrees. Running bd commands from a .claude/worktrees/* checkout writes to the same database the main checkout reads from. The .beads/issues.jsonl file in any worktree is a stale snapshot from worktree creation, NOT the live source of truth — don't be alarmed when it doesn't change after bd writes; don't redo bd commands; don't go searching for DB paths. Trust bd's exit code: success means persisted globally.

(2) 'bd dolt push' is usually a no-op in these projects — no Dolt remote is typically configured (verify with 'bd dolt remote list'). The git-tracked .beads/issues.jsonl is the source of truth and propagates via normal 'git push'. Skip 'bd dolt push' in the session-close workflow unless a Dolt remote has been set up; do not treat its informational 'Supported remote URLs' output as needing fixing.
EOF
)"
```

## Verifying

```bash
bd memories                         # list all keys
bd recall <key>                     # show one memory's body
```

## Adapting after seeding

These start out generic. As project specifics emerge (build tool, dev
preview command, additional doc paths beyond `docs/`, sub-doc files like
`SCIENCE.md`, etc.), rewrite the memory bodies in place via
`bd remember --key <key> ...`. `bd remember` is upsert-by-key, so a fresh
call with the same `--key` overwrites the stored body. Don't append
amendments — re-author the full body each time so each memory stays
self-contained.

If a memory turns out not to apply (e.g. there's no doc directory, so
the defer-doc-updates examples don't fit), either edit it to fit or
remove it with `bd forget <key>`.
