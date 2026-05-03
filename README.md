# project-defaults

Personal development environment defaults — git, GitHub, linting, formatting,
Claude Code config, husky, beads.

## Using these defaults

Open Claude Code in a fresh repo and say:

> Read `~/github/alexmensch/project-defaults/SETUP.md` and apply the defaults
> to this repo.

[`SETUP.md`](SETUP.md) is a self-contained prompt that walks Claude through
the setup, asking the right questions and copying / merging the relevant
templates.

## Layout

```
claude/         Claude Code config — settings.json (with bd hooks +
                memory-guard) and a CLAUDE.md template
editors/        Sublime Text user preferences (one-off, not per-repo)
git/            Global git config + .gitignore / .gitattributes templates
github/         FUNDING.yml + master branch protection ruleset (gh import)
husky/          Default pre-commit and pre-push hooks
lint/           Prettier, ESLint, Stylelint, markdownlint configs +
                package.json scripts/devDependencies partial
scripts/        Standalone shell scripts (e.g. branch sync helper)
```

## Manual one-time setup (not for SETUP.md)

```bash
# Global git config — paste contents of git/git-config
git config --global -e

# Sublime Text — copy editors/Preferences.sublime-settings into the
# user Packages/User/ directory
```

The above are user-level rather than per-repo, so the SETUP.md prompt skips
them.
