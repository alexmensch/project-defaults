---
name: implement-feature
description: Follow a standard workflow for feature implementation in a project that ensures that a technical spec drives both test writing and implementation in parallel, followed by a code review that is always performed before a pull request is submitted to the default branch of the project's code base.
---

When implementing a new feature or new functionality in an existing codebase, you must adhere to the steps that follow with the goal of creating high quality, efficient, and clear code at all times. Follow these steps in strict order:

1. Before starting work, always create a new branch. Make sure that the default branch is at the latest version and make sure the new branch is created from the default branch. Never work in the default branch for the project, which is usually `master`, but may also be `main` in some cases. I do not care what the branch is called, you can decide.
2. Require descriptive precision from the user's request when starting to implement a new feature. If there is ambiguity in changes that the user is requesting, without being pedantic, you must ask the user for clarification. Pass the clarified requirements to the technical-spec agent. The technical-spec agent will deeply analyse the codebase, produce a structured technical specification with a requirements table, and confirm the spec with the user within its own session. You will receive the approved spec back.
3. Once you have the approved technical spec, start two things in parallel: hand the full technical spec to the test-writer agent (which runs in the background in an isolated worktree), and begin writing implementation code yourself against the same spec. Both you and test-writer work from the requirements table in the technical spec.
4. Once both you and the test-writer have finished, merge the test-writer's worktree changes into the current branch. Then run all tests for the whole project. In no circumstances will you change any code in the tests without confirming with the user first. The strong principle here is that tests are written to cover desired functionality, not just to pass. Never change tests just to make them pass — you must determine whether there is a genuine bug in the code you wrote first. If you think there is a bug in a test, confirm with the user first. This step is completed when all tests pass.
5. Next, invoke the code-reviewer agent. It will review all changes on the branch, present findings to the user, make the user's approved changes, and create a single commit for the code review fixes.
6. Run the linting tool that's configured for the project.
7. Run either the build command or mock deploy command for the project to ensure there are no build errors. Ensure that you do not build or deploy the project to production, you are only ensuring the project builds, deploys, or compiles correctly.
8. Update README.md and CLAUDE.md in the project root for changes that are functionally noticeable to a user or developer of this codebase. Bug fixes, refactors, internal renaming, and test changes do not require documentation updates unless they change something observable from the outside.
9. If the project uses semver and this change is being released, update the relevant files according to the set of changes being made, following semver conventions for major, minor, patch. Usually package.json and manifest.json contain semver versions for the project, but check the project CLAUDE.me documentation if in doubt, and add this information to CLAUDE.md if it is not already there. If you are not certain that the version should be updated, ask the user.
10. As the final step, you will ask the user to commit all changes and create a PR.

## Agent dependencies and handovers

### Dependencies

If the agents described above are not available, stop the session and ask the user to correct this. The intent is that they are located in the user's configuration, not the project.

### Handovers and sequences

The data handovers and sequencing listed in the steps above are:

1. User input -> you clarify -> clarified requirements passed to technical-spec agent (foreground)
2. technical-spec agent analyses codebase, produces spec, confirms with user in its own session -> approved technical spec returned to you
3. You hand the approved spec to test-writer (background, isolated worktree) AND begin writing code yourself — these happen in parallel
4. Once both finish -> merge test-writer's worktree into the current branch -> run all tests
5. code-reviewer reviews, presents findings to user, makes approved fixes, commits
6. Remaining steps (lint, build, docs, semver, PR) completed in order

## Commit granularity

Make multiple commits at each stage of the process above. I expect a single commit for initial test implementation, individual commits for each discrete aspect of the user requirements, a single code review commit, and then a single commit for all remaining steps.

## Avoiding repetition

For all tasks above that ask you to run a particular tool, for example, linting, build, mock deployment, etc. look for this information in CLAUDE.md so that you do not have to scan the codebase every time you need project tooling information. If the information is not already in CLAUDE.md, add it. If the information in CLAUDE.md is incorrect, update it with the correct information.

The principle here is that you should minimise repeating the same task, which is slow, takes up more session context, and eats up account usage.

## Code quality principles

These principles apply whenever you write or modify code in this project.

- **Less code is better.** If a change can be made with fewer lines, prefer that. Do not add code speculatively.
- **Keep it DRY.** Never define the same string, value, or logic in more than one place. Use constants and shared utilities.
- **Reuse before creating.** Before writing a new function, class, or module, search the codebase for something that already does what you need. Extend or adapt existing code rather than writing parallel code paths.
- **No unnecessary dependencies.** Do not add a new package or library unless there is genuinely no reasonable way to solve the problem with what is already available.
- **Solve the root problem.** Do not patch symptoms. If something is broken upstream, fix it there rather than working around it downstream.
- **No speculative abstraction.** Do not create new utility functions, base classes, or abstractions unless they are immediately needed by the current task.
