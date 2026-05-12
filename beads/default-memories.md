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
# ===== Git / workflow rules =====

bd remember --key alex-never-push-to-main "$(cat <<'EOF'
# 🚨 NEVER push to main/master. NEVER commit to main/master. NEVER. 🚨

ABSOLUTE RULE — no exceptions, no rationalisations, no "tiny change" carve-outs, no "just this once" reasoning, no historical-pattern excuses.

Every change — including 10-line timestamp updates, .beads/issues.jsonl syncs, doc tweaks, typo fixes, anything at all — goes through:

1. Fresh git worktree (call EnterWorktree).
2. Feature branch.
3. Push the branch with -u.
4. gh pr create (attach skip-version-bump if no shipped code, where applicable).
5. Merge through the GitHub UI / CLI.

Never `git push origin main` (or master). Never `git commit` on main/master directly. Never bypass the PR path "because the diff is trivial". The size of the diff is not a justification — the rule is unconditional.

Why this rule exists: set explicitly by Alex. Repeat-offending on a directly-set rule is the worst possible failure mode in this collaboration — worse than any individual technical mistake. Alex's framing: "you must NEVER NEVER NEVER break rules that I set for you."

How to apply:
- At session-end cleanup time, if there's a tempting "small change on main" to push: STOP. The answer is always "do it through a worktree + PR" or "leave it for the next PR to carry."
- If the rule appears to conflict with another instruction or a historical-pattern observation, the rule wins. Always. Ask Alex if genuinely uncertain — never decide unilaterally.
- If the rule has already been broken, surface it immediately and offer the correct revert path. Don't downplay.
- Re-read this memory at session-close, especially around any cleanup involving .beads/, post-merge sync, or "should I push this small thing."
EOF
)"

bd remember --key gh-auto-delete-on-merge "$(cat <<'EOF'
Alex's GitHub repos have auto-delete-on-merge enabled in repo settings: feature branches are deleted from the remote automatically when a PR merges.

How to apply: cleanup after merge is local-only. Run `git fetch --prune`, then `git worktree remove` for the worktree and `git branch -D` for the local branch. Do NOT run `git push --delete origin <branch>`; the remote-side delete already happened and the command will fail or no-op.

If a specific project ever turns this off, the symptom is `git fetch --prune` not removing the merged branch on the remote — at that point either re-enable in repo settings or add the explicit `git push --delete` to that project's session-close.
EOF
)"

bd remember --key commit-granularity "$(cat <<'EOF'
Prefer small topical commits: when a change touches multiple concerns, split them into separate commits each with a focused subject line and brief why-body.

Why: one-concept-per-commit keeps the repo's story legible and makes revert/bisect surgical.

How to apply: when there are unrelated staged changes, don't reach for one omnibus commit message — stage and commit each concern separately. Err toward more commits, not fewer. Keep using HEREDOC commit format with the Co-Authored-By: Claude trailer.
EOF
)"

# ===== PR practices =====

bd remember --key alex-pr-review-style "$(cat <<'EOF'
PR review style — when Alex asks to review a PR before merging.

Persona: engineering manager reviewing code; demanding, precise, strict.

What to evaluate (in priority order):
1. Coding elegance — no brute-force approaches, no jank
2. DRY — keeping things DRY is paramount; flag duplicated logic, magic numbers, parallel implementations across files
3. Bigger architectural picture — not just the changed lines; how the change fits the codebase's existing patterns and conventions
4. Tests — identify tests that need updating or adding

Output format: concise report with what should be changed and why, then GET APPROVAL before proceeding with any fixes. Do NOT start fixing until Alex agrees with the findings.

Out-of-scope findings: file as bd issues under the project's active code-quality epic (if one exists; create one if not and the project has accumulated 3+ such findings). Don't lose architectural debt to chat-only mentions.

How to apply: when invoked via "review PR N" / "review this branch" / similar phrasing, fetch the PR diff (gh pr view, gh pr diff), read the files in full not just the hunks (to evaluate architectural fit), check both the changed code and adjacent code paths the change interacts with, scan tests for coverage gaps, then deliver findings without unsolicited fixes.
EOF
)"

bd remember --key alex-large-pr-honesty "$(cat <<'EOF'
For large multi-bead PRs (~10+ issues in one PR) Alex authored, proactively distinguish code with strong unit-test coverage from code that requires manual verification. Flag specific test-plan gaps rather than implying overall confidence.

Confidence categories at PR-open time:
- High: changed code paths exercised by unit/integration tests.
- Medium: tests cover adjacent code but not the integration point.
- Low (needs eyeballs): user-visible paths with only unit-level coverage; constructor signature changes; callback rewiring; build-pipeline scripts; generated artifacts.

How to apply at PR-open time:
- Audit the manual-smoke checklist against the actual diff.
- Add an explicit smoke step for any user-visible path with only unit-level coverage.
- Refactors that change a constructor signature or callback wiring always get a smoke step.
- Scripts/pipelines need at least a "run it and check the log line" smoke.
- Distinguish "tests pass" from "behavior verified" in the PR description so reviewers can prioritize their manual passes.
EOF
)"

# ===== Code quality (these override Claude Code system-prompt defaults) =====

bd remember --key named-constants-and-dry "$(cat <<'EOF'
Two paired rules to prevent magic-number / DRY findings at code-review time. These rules OVERRIDE the Claude Code system prompt's "Three similar lines is better than a premature abstraction" / "a bug fix doesn't need surrounding cleanup" defaults. Project CLAUDE.md should restate the override so it survives system-prompt drift.

1. Hoist numeric literals to named consts at first sight of a second usage. Any literal that is referenced in more than one place — or that encodes a tuned/calibrated value (pixel thresholds, mag-biases, near/far clamps, bit positions) — gets a named export at its canonical source module. Tests IMPORT it, never redefine. If a literal is calibrated by feel, it MUST be named — the name documents intent.

2. Schemas / structures / functions that are mostly-identical share a builder. When v2 and v3 of a wire schema differ only in 4 of 20 entries, or two materials differ only in their blend equation, or two parsers differ only in the projection of fields, or two solvers differ only in tolerance and wrap convention — extract a builder/factory/helper and parameterise the differences. Verbatim duplication of large blocks is the strongest signal of latent drift. "Slightly different X and Y" between two call sites is the case FOR extracting, not against it — the difference becomes a parameter.

Why: Code-review patterns consistently surface DRY / magic-number findings. The cost of one shared module beats the cost of (a) future drift, (b) review burden when each consumer must be cross-checked, and (c) tests redefining canonical constants and silently desyncing.

How to apply:
1. When typing a numeric literal, pause and ask: is this value (or the same dimension — e.g. another pixel-distance threshold, another bit position, another empty-vec3 default) referenced anywhere else? If yes, hoist to a const in the most upstream module.
2. When two functions / constants / schemas share more than ~50% of their bodies, ask whether the differences are parameters of one shared definition. If yes, extract the builder.
3. Tests: never redefine a constant the production code exports. Import it.
4. Comment-DRY counts too: if the same caveat appears verbatim in two consumer files, hoist the comment to the source helper.

Common misattribution to watch for: if you find yourself drafting reasoning like "Lifting it to a shared module is tempting but each call site has slightly different X and Y. Default: copy-paste with attribution comment, lift later only if a third call site appears. Avoids premature abstraction per CLAUDE.md" — STOP. That reasoning is wrong. "Slightly different X and Y" between two call sites is the trigger for rule 2 above — parameterise the differences and extract. The two-call-site threshold is firm. Do the extract; pass the differing values as parameters.
EOF
)"

bd remember --key pattern-coverage-across-peers "$(cat <<'EOF'
When a PR is framed as "apply pattern X to all the Y in this layer" (every overlay, every event handler, every picker entry point, every shader pass, every DRY blend), enumerate the set of Y EXPLICITLY in the PR description AND verify the implementation covers each. One missed peer = the PR headline claim is false.

Why: recurring code-review finding shape across multiple PRs. Representative example: a PR claimed "all five remaining overlay modules" got dirty-tracking but a sixth peer was missed (and the most-instantiated one in the hot path) — the headline claim was false because one peer was missed. Pattern divergence in the same layer is exactly what "architectural fit" reviews catch — much cheaper to fix at write time than at retrospective.

How to apply:
1. Before starting the refactor, write the explicit list of peers in the PR description. Skim CLAUDE.md's module roster for the cross-cutting layer being touched (overlays, picker, event handlers, debug-panel sections, shaders, etc.) — it is the canonical list of peers.
2. After implementing, grep for the OLD pattern (the thing being replaced) and confirm ZERO remaining call sites in scope. If non-zero, either convert them or call them out as "deliberately deferred" with a follow-up bead.
3. If two peers in the same layer end up with two strategies (e.g. per-attribute dirty-track vs whole-frame signature dirty-track), document the chosen strategy in the layer-canonical doc and pick one for the layer or reconcile.
4. Sister-layer extension — when extending a feature for one host, check whether sibling hosts have the same surface and would benefit / drift if not extended too. File a bead for the sibling work even if out of scope.
EOF
)"

bd remember --key rename-sweep "$(cat <<'EOF'
When a PR renames or removes an API surface (function, method, event, class, mechanism, or named threshold), grep the entire repo for the OLD names AND for prose descriptions of the old behaviour, and update both in the SAME commit. Specifically: code comments referencing removed methods; docs/*.md describing removed mechanisms; citations and numerical sanity-checks in reference docs; inline contracts on type declarations; perf-hud / telemetry marker labels; HTML <title> / modal copy; release-notes / version-classification when behaviour changes.

Why: recurring "comment / doc / marker still says old name" finding shape. No test catches them; the next reader is misled. Representative shapes: perf marker `onFrame.total` after the event was renamed to `frame`; a doc trade-off paragraph describing a mechanism that the same PR removed.

How to apply: before commit, treat the rename as a sweep, not just a refactor.
1. `grep -rn "<old-name>" .` (skip node_modules, .git, public/) — triage every hit.
2. Open every doc file in the diff context (docs/*.md, README.md, CLAUDE.md, RELEASING.md, project reference docs) and re-read it as if seeing it the first time. Stale prose is the most common drift class.
3. When changing the semantics of a quantity referenced in a docblock, open the docblock and re-read its rationale. If the change invalidates the prose, update the prose.
4. Numerical sanity-check examples in docs need to be sanity-checked themselves — paste-compute them, do not trust the original author.
5. Release-notes / version classification: a user-visible behaviour change is at minimum a minor bump even if the diff is small.
EOF
)"

bd remember --key test-coverage-discipline "$(cat <<'EOF'
When writing code, add tests in the SAME PR for: (a) pure helpers — extract them to module-scope (or a separate file) so they are testable, then test; (b) numeric headline claims in the PR description — pin with `expect(x).toBe(N)`, never `toBeLessThanOrEqual(N)`; (c) integration paths through new state machinery — allocate/grow/write/flush/shift cycles for typed-array buffers, multi-tier reducers, lifecycle FSMs all need a read-back assertion, not just a "does not throw" smoke; (d) auto-upgrade / migration paths (e.g. v2→v3 URL rewrite) that the test plan flags as "manual smoke."

Why: recurring code-review test-gap finding shape. Representative shapes: pseudo-private pure helper not exported (so untestable); PR description claims a specific number ("URL drops to 10 chars") but the test only asserts `≤ 12`. Manual-smoke fallback regresses between releases — automated tests do not.

How to apply: before opening a PR, audit the diff:
1. New function or class? Does each have a test? If pseudo-private, lift to module scope or a `*-pure.ts` sibling.
2. Numbers in the PR title / summary / release notes? Each one must pin with `toBe(N)` somewhere. `toBeLessThanOrEqual` only catches regressions that grow past the bound — not what the headline is selling.
3. New typed-array plumbing (allocate / grow / write / flush / shift)? Add a read-back test that attaches a host with known values, triggers the grow + shift, and asserts the buffer contents at known offsets.
4. Two-tier / N-tier control flow (prime vs fallback, polynomial vs simpler-model)? Each tier must be exercised; the priority semantics must be a separate assertion.
5. PR test plan flags any path as "manual smoke"? Promote the cheapest of those (5–10 line vitest) to automated. Manual smokes are the weakest layer of the regression-prevention strategy.
EOF
)"

# ===== Docs hygiene =====

bd remember --key defer-doc-updates "$(cat <<'EOF'
Defer doc updates until the final commit. Don't edit CLAUDE.md, README.md, anything under docs/, or other project reference docs while implementing a change — treat code changes as the only deliverable until commit time.

Why: mid-session doc edits become churn — direction shifts, features get dropped, parameters rename, knob values move; the paragraph written early ends up describing something that no longer exists.

How to apply: during implementation confine edits to code, templates, styles, tests; if a code comment references a doc section about to be wrong, leave it and surface at commit time. At commit time, grep the final diff for renames, removed knobs, new uniforms, behavioural shifts, anything user-visible — open CLAUDE.md, README.md, docs/, and project reference docs and update only what's now stale. Skip ones that don't need changes.
EOF
)"

# ===== Beads operational facts =====

bd remember --key bd-persistence "$(cat <<'EOF'
How bd state persists — two related operational facts:

(1) bd state is shared across all git worktrees. Running bd commands from a .claude/worktrees/* checkout writes to the same database the main checkout reads from. The Dolt DB at .beads/embeddeddolt is the live source of truth. The git-tracked .beads/issues.jsonl is exported from Dolt by a pre-commit hook on every commit and propagates bd state across git — but it lags the live DB until the next commit. So the .beads/issues.jsonl file in any worktree is a stale snapshot from creation, NOT the live source of truth — don't be alarmed when it doesn't change after bd writes; don't redo bd commands; don't go searching for DB paths. Trust bd's exit code: success means persisted globally.

(2) 'bd dolt push' is usually a no-op in these projects — no Dolt remote is typically configured (verify with 'bd dolt remote list'). The git-tracked .beads/issues.jsonl is the source of truth and propagates via normal 'git push'. Skip 'bd dolt push' in the session-close workflow unless a Dolt remote has been set up; do not treat its informational 'Supported remote URLs' output as needing fixing.

(3) JSONL handling: don't revert .beads/issues.jsonl when it appears modified or staged. The pre-commit hook keeps it in sync; no Claude action required. Feature commits bundle the JSONL diff alongside code changes — that's expected; don't carve it into a separate commit. Need a clean tree (e.g. for `git pull --rebase`)? Regenerate via `bd export -o .beads/issues.jsonl` so the file matches the *current* live DB, not HEAD. Then stash/leave-unstaged/commit — never `git checkout --` it. Verify JSONL matches live DB: grep an issue ID, confirm `status` field matches `bd show <id>`.
EOF
)"

bd remember --key concurrent-claude-sessions "$(cat <<'EOF'
Concurrent Claude sessions: bd issues marked in_progress with matching uncommitted edits in the worktree usually indicate another live session is working on that bead. Do NOT pick it up, run quality gates against it, stage/commit/push, or close the bead. Confirm with the user first. The 'Status: in_progress' field is the canonical 'someone else has this' signal — git branch ownership alone is not enough because branches are shared across sessions.
EOF
)"

bd remember --key bd-create-deps-direction-trap "$(cat <<'EOF'
bd dep CLI direction trap. The CLI signature is `bd dep add <depender> <depended-on>` (positional). The FIRST id is the issue that depends on (is blocked by) the SECOND. Default relationship type is `blocks`.

Three equivalent forms — pick the clearest:

    bd dep add <depender> <blocker>                    # positional (cleanest)
    bd dep add <depender> --blocked-by=<blocker>       # flag form
    bd dep add <depender> --depends-on=<blocker>       # alias of --blocked-by

There is NO `--blocks` flag on `bd dep add` — only `--type=blocks` (the relationship type, defaulted). Writing `bd dep add A --blocks B` will fail with "unknown flag".

For non-blocking links pass `--type=related` (or `tracks`, `discovered-from`, `caused-by`, `validates`, `relates-to`, `supersedes`, `until`, `parent-child`).

`bd create --deps` direction trap:
- `--deps=blocks:X` makes the NEW issue block X (opposite of "depends"). Useful when filing a blocker for an existing issue in one shot.
- `--deps=<plain-id>` (no type prefix) means the new issue DEPENDS ON `<plain-id>` — the natural reading.

After any dependency write, verify with `bd dep list <new-issue>` and `bd ready`. The phrasing in `bd dep add`'s success message ("A depends on B (blocks)") confirms direction explicitly — read it.
EOF
)"

bd remember --key bd-multi-line-writes "$(cat <<'EOF'
Canonical form for any multi-line bd write (bd remember, --description, --notes, --design):

    bd remember --key foo "$(cat <<'EOF_INNER'
    body content here, verbatim
    EOF_INNER
    )"

Inside `<<'EOF'` (single-quoted delimiter), the shell does NO backslash interpretation — the body is passed to bd verbatim. Do NOT escape quotes or backticks in the source: a `\"` or `\`` written in the body is stored as the literal two-character sequence (backslash + quote / backslash + backtick), not as `"` or `` ` `` alone. bd does not unescape on store, so the artifacts are visible to every future reader and the memory looks corrupted.

Symptom: previewing with `bd memories <key> --json` shows `\"` or `\`` where you wanted plain `"` or `` ` ``.

After any multi-line write, sanity-check by reading the body back. Cheap; protects against silent corruption no test catches:

    bd memories <key> --json | python3 -c "import json,sys; print(json.load(sys.stdin).get('<key>',''))" | head -40

Same rule applies to bd create --description=, bd update --notes=, bd update --design=, and any other multi-line content routed through the same heredoc form.
EOF
)"

bd remember --key bd-tagging-conventions "$(cat <<'EOF'
Tagging, metadata, and external refs — keep structured info OUT of titles. bd offers three structured-metadata mechanisms with very different filterability. Use the right one so future search/grouping is a one-liner, not a `--title-contains` scan.

- Labels (--labels foo,bar, bd tag <id> <lbl>, bd update --add-label) — flat string tags, multi-valued, filterable through every path: bd list --label X, --label-any X,Y, --label-pattern 'pr-*', --label-regex, AND in bd query "label=X". bd label list-all shows the full namespace. Children inherit parent labels by default (--no-inherit-labels to skip). This is the only mechanism bd query natively understands — make labels the default for anything you'll want to filter on later.
- --external-ref (e.g. gh-45, jira-ABC) — single string per issue, semantic anchor for tooling. NOT queryable via bd query, no native bd list filter — only visible in bd show and JSON export. Use it as a canonical pointer, not as a search axis.
- Metadata (--metadata '{...}', repeatable --set-metadata key=value) — typed key→value JSON. Filterable via bd list --metadata-field key=value and --has-metadata-key=key. Best for values you want to retrieve, not just match (URLs, DOIs, version numbers). Not queryable via bd query.

Conventions (forward-only — don't retrofit existing beads unless asked):

- PR numbers → label `pr-<num>` (e.g. pr-45). Drop [PR #N] title prefixes going forward; the label replaces them. bd query "label=pr-45" answers "all beads from PR 45". bd list --label-pattern 'pr-*' enumerates every PR-tagged bead. Multi-PR beads (review-discovered then fixed in a different PR) carry multiple pr-N labels naturally. Bare digit labels would clash with bead-ID lookups, so always use the `pr-` prefix.
- Optional canonical anchor: also set --external-ref=gh-<num> on the originating PR. Useful for future link-out tooling, but not a substitute — the label is what makes it queryable.
- URLs / DOIs / dashboard links → metadata, keyed by source-type: paper-doi, dashboard-url, gh-issue-url, version-fixed, etc. Surface with bd list --has-metadata-key=paper-doi. Don't bury URLs only in description prose if they should be re-findable.
- Topical area / process state → keep existing labels. Don't invent parallel labels for the same concept; check bd label list-all before coining new ones. Coining a brand-new label for a single bead is rarely worth it — wait until the concept appears in 2+ beads.
- Naming: lowercase, kebab-case, no spaces. Metadata keys same shape (descriptive kebab-case).
EOF
)"

# ===== Beads authoring discipline =====

bd remember --key bd-authoring "$(cat <<'EOF'
How to author and maintain bd content well across sessions.

(1) Prefer formal bd dep links over prose cross-references whenever the relationship affects planning, ordering, or future work decisions. Alex plans from the dependency graph (bd ready, bd dep list, bd show) — prose 'see issue X' references don't surface there and are easy to miss. Use 'bd dep add' for blocks, the relate variant for relates_to, --parent for parent-child. After filing a batch of issues, audit own descriptions for cross-reference prose and convert each to a formal link before declaring done. Use 'relate' for cross-epic connections (bd's blocks between epics often errors). Avoid epic-level blocks when task-level deps can express the same constraint, since open parents with inbound blockers cause bd ready to cascade-block all children.

(2) Same principle for structured info other than dependencies: PR numbers, URLs, source-type tags belong in labels / metadata / external-ref (see bd-tagging-conventions), not in title prose or buried in descriptions. Title scans and free-text grep don't survive volume; structured fields do.

(3) When you notice a bd memory is stale, deficient, or contradicts current repo state, update it via 'bd remember --key <existing-key> ...' immediately rather than just noting it in chat. Why: Alex wants memories actively maintained — drift compounds across sessions if corrections aren't written back, and the next session reads the stale version. How to apply: when reading a memory whose specifics don't match current code/config (referenced file no longer exists, flag renamed, policy changed, commit hash referenced is gone, etc.), re-author the memory body in place. Rewrite the whole body each time so it stays self-contained; fragmented amendments are hard to read. Same applies to memories about commands, paths, and project structure.
EOF
)"

bd remember --key bead-authoring-scope "$(cat <<'EOF'
How to scope a new bead so Alex doesn't have to ask for a re-split later.

The rule: Each bead = one commit/PR + a stated smoke/test step. Sized to fit a compact context window so it can be tackled with a session reset between beads. If the work is bigger, file an epic with children at creation time — not a single bead that needs splitting later.

Why: Bigger beads bundle multiple commits, force session resets mid-bead, and make review noisier. Doing this at creation time saves Alex from asking for a re-split.

How to apply — natural seams to decompose along:

Before filing, ask: would this be one commit + one smoke step, or several? If several, file an epic with children. Common seams:

- Research / decision → implementation. If the bead has "decide X" or "evaluate Y" before code lands, split. Research is a written-output deliverable; implementation depends on its conclusion.
- Data pipeline → runtime. Build script + output artifact is one commit; consumer / runtime loader is another. Pipeline ships independently; runtime tests against committed artifacts.
- Independent affordances bundled together. When the description says "two related X filed in one issue," or enumerates independent features, file each as its own bead.
- Distinct sub-system additions, even if they share a parent epic.
- Per-source / per-type ingest, only if each source is independently shippable and useful — don't split if the value is the unified output.

Don't decompose when work is genuinely indivisible: a single bug fix, a focused refactor, a decision producing one output, a small UX tweak that's one DOM/CSS change.

Wiring at creation time:
- Convert parent to --type=epic when it acquires children.
- Keep the parent's master spec in its description; children carry focused per-task scope + acceptance criteria + smoke step.
- Use bd dep <depender> <blocker> between siblings to express ordering (research blocks impl, pipeline blocks runtime). Use --type=related for cross-cutting non-blocking relationships. Never rely on prose "see issue X" — Alex plans from the dependency graph.
- If parent is deferred, defer children too via bd defer.
- Verify with bd dep list <new-issue> + bd ready immediately after — direction is the common landmine (see bd-create-deps-direction-trap).
EOF
)"

bd remember --key bd-data-grooming-protocol "$(cat <<'EOF'
How Alex likes bd data (memories + issues) groomed for context efficiency and prioritised execution.

Two paired passes — memory pruning and issue grooming — both about signal-to-noise: memories load every session, and open issues drive 'bd ready'. Bloat in either silently degrades how useful bd is.

Why: Memory bloat dilutes session context. Mis-prioritised or cluttered open issues break the prioritisation framework. Both compound between grooming passes if not maintained.

How to apply: Run grooming when Alex asks ("prune memories", "groom beads", "check what's worth retiring", or similar). Survey first, present a categorized plan, wait for approval, then execute mechanically in batches.

=== Memory pruning ===

Categorize each into drop / trim / consolidate / keep.

- Drop when content lives elsewhere: a relevant bead (search bd first — bead descriptions often have richer context than the memory), canonical docs (CLAUDE.md, RELEASING.md, docs/*, project reference docs), time-bound notes aged out without follow-up, or lessons from abandoned PRs once the conclusion is settled product policy.
- Trim by keeping rule + why + how-to-apply; drop historical incident logs, exact dates, sub-task IDs, file:line paths that belong in code comments. For memories that group rules into shapes, keep one representative example per shape — not the full enumeration.
- Consolidate multiple memories on the same operational area with non-overlapping scope into one structured memory with sections.
- Move long technical content (invariants, file paths, debug HUDs) into the project's architecture/docs and a code comment at the call site, then drop the memory.

Decision rule: if it's not relevant to every session, it doesn't belong in memory. Beads/docs are the right home for area-specific content.

=== Bead grooming ===

Survey via 'bd list --status=open --limit=0 --json'; the tree output paginates and is hard to read at scale, so script the grouping with python (parent/child via dependencies[].type='parent' or 'parent-child').

Categories:
1. Duplicates — close with bd close <id> --reason='duplicate of <other>'.
2. Strays under existing epics — reparent with 'bd update <id> --parent <epic>'.
3. New epics — when 3+ coupled beads should land together; create the epic and call out the design-gate child in the description.
4. Orphaned children from closed epics — reparent to the surviving parent.
5. Re-prioritisation against the project's prioritization framework:
   - Research / "investigate" tasks at P1 → P2 (P1 is for in-flight rewrites, not upstream research)
   - Code-quality children default to P3 unless coupled to in-flight P1/P2 work
6. Defer candidates — 'bd defer <ids...>' (status-based, no --until needed). Common categories Alex tends to defer:
   - Mobile work, until desktop is solid
   - Public site / FAQ / marketing, until ready to ship
   - Far-out / low-impact features
   - Polish that isn't on the critical path
   - Small UX decisions filed for "someday" (defer until they actually matter)

Specific judgment calls worth asking Alex about before executing: research-stage P1 → P2 transitions, whether specific cleanup tasks are still live or now obsolete, and whether to defer entire epics vs just children.

Verify with 'bd ready' post-grooming — should be meaningfully shorter and reflect actual scope.
EOF
)"

bd remember --key task-tracking-policy "$(cat <<'EOF'
Project policy for task tracking — overrides bd prime's built-in "Prohibited: Do NOT use TodoWrite, TaskCreate, or markdown files for task tracking" Core Rule. The bd built-in is too strict; the split below is the actual policy.

The split:

- Beads is the canonical tracker for anything that should outlive this session — new tasks, bugs, refactors, follow-ups, design decisions. Create a bead BEFORE writing code, mark in_progress when starting, close when shipped.

- TaskCreate / TodoWrite is allowed for in-session step decomposition — discrete sub-steps of an in-flight bead too granular to file individually and with no value next session (e.g. "update import in file X", "regen catalog", "run vitest", "open PR"). The bead is the unit of persistent work; the task list is a working surface for executing it.

- Tie-break: when in doubt, file a bead. Persistence you don't need beats lost context. If a sub-step turns out to be its own piece of follow-up work, promote it to a bead and close the task entry.

- Never use markdown TODO files (TODO.md, NOTES.md, etc.) — they decay silently and aren't searchable.

Why: The bd built-in rule conflates "ephemeral tracking is wasteful when work outlives the session" (true) with "ephemeral tracking is bad in itself" (not true). TaskCreate has a real job — a live ticking checklist for multi-step work happening in this session — that beads doesn't do well, and a bead per micro-step is noise in bd ready and noise in the JSONL diff.

Lives as a memory rather than in CLAUDE.md because the Beads section of CLAUDE.md is inside an auto-managed BEGIN BEADS INTEGRATION block — easily clobbered on bd integrate refresh. Memory survives.

How to apply:
- Default: file a bead. TaskCreate is for the sub-steps INSIDE an in-flight bead, not for the principal work.
- Single-step changes (one-line edit, one quick fix, a docs typo) need neither — just do them.
- If a sub-step in the TaskCreate list grows into "needs more thought / its own commit / cross-session work", lift it to a bead immediately and remove the task entry.
- Do not invent parallel TaskCreate lists for work that already has a bead — the bead's notes / description carries that record.
EOF
)"

# ===== Web / external access =====

bd remember --key web-access-loops "$(cat <<'EOF'
Don't loop on failed web fetches. If a URL access fails (404, blocked, auth wall, AI-scraper filter, etc.), do NOT keep trying alternative transports (WebFetch -> curl -> different URL -> etc.) in a loop.

Why: the user flagged this explicitly — they don't want time and tokens burned on transport attempts that aren't converging. It's faster for them to grab it manually than to thrash.

How to apply: on the first failure, try one alternative. On the second failure, stop and ask the user to fetch the content themselves and paste it in (or drop the file into the repo, or give the information directly). Tell them the exact URL being attempted so they can fetch it with minimal context-switching.
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
