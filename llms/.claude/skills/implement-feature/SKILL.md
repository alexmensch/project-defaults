---
name: implement-feature
description: Follow a standard workflow for feature implementation in a project that ensures that tests are always written first based on the feature spec description, followed by implementation against those scenarios, and ending with a code review that is always performed before a pull request is submitted to the default branch of the project's code base.
---

When implementing a new feature or new functionality in an existing codebase, you must adhere to the steps that follow with the goal of creating high quality, efficient, and clear code at all times. Follow these steps in strict order:

1. Before starting work, always create a new branch. Make sure that the default branch is at the latest version and make sure the new branch is created from the default branch. Never work in the default branch for the project, which is usually `master`, but may also be `main` in some cases. I do not care what the branch is called, you can decide.
2. Require descriptive precision from the user's request when starting to implement a new feature. If there is ambiguity in changes that the user is requesting, without being pedantic, you must ask the user for clarification. Pass this information to the technical-spec agent, which will take this information and create a technical spec that matches the discrete user requirements.
3. A separate agent, test-writer, must write tests for the requested functionality from the user. No code will be written until these tests have been written in the codebase. Once test-writer has completed its work, tests will fail until you write code that satisfies those tests.
4. You will write the code against the technical spec that the technical-spec agent created. Once you have written all of your code, and only after you have written all of your code, you will run all tests for the whole project. In no circumstances will you change any code in the tests without confirming with the user first. The strong principle here is that tests are written to cover desired functionality, not just to pass. Never change tests just to make them pass, you must determine whether there is a genuine bug in the code you wrote first. If you think there is a bug in a test, confirm with the user first. This step is completed when all tests pass.
5. Next, you will invoke the code-reviewer agent, which will review the codebase and interact with the user as necessary to make additional refinements.
6. Run the linting tool that's configured for the project.
7. Run either the build command or mock deploy command for the project to ensure there are no build errors. Ensure that you do not build or deploy the project to production, you are only ensuring the project builds, deploys, or compiles correctly.
8. Update README.md and CLAUDE.md in the project root for changes that are functionally noticeable to a user or developer of this codebase. Bug fixes, refactors, internal renaming, and test changes do not require documentation updates unless they change something observable from the outside.
9. If the project uses semver and this change is being released, update the relevant files according to the set of changes being made, following semver conventions for major, minor, patch. Usually package.json and manifest.json contain semver versions for the project, but check the project CLAUDE.me documentation if in doubt, and add this information to CLAUDE.md if it is not already there. If you are not certain that the version should be updated, ask the user.
10. As the final step, you will ask the user to commit all changes and create a PR.

## Agent dependencies and handovers

### Dependencies

If the agents described above are not available, stop the session and ask the user to correct this. The intent is that they are located in the user's configuration, not the project.

### Handovers and sequencies

The data handovers and sequencing listed in the steps above are:

1. User input -> your review -> technical-spec agent
2. technical-spec agent -> agent will ask user to review before completion -> technical spec that you receive
2. technical spec -> test-writer agent agent in background and isolation
3. You write code against technical spec
4. After test-writer has finished, and you have finished writing code, you run tests against your code
5. Remaining steps completed in order as described above

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
