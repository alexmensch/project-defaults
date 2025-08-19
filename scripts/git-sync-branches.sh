#!/bin/bash

# Fetch all branches from remote
git fetch --all

# Prune deleted branches
git remote prune origin

# Delete local branches that are not on the remote
for branch in $(git branch | sed 's/*//'); do
  if ! git show-ref --quiet refs/remotes/origin/${branch}; then
    git branch -D ${branch}
  fi
done

# Create new local branches for new remote branches
for branch in $(git branch -r | grep -v '\->' | grep -v 'origin/HEAD' | sed 's/origin\///'); do
  if ! git show-ref --quiet refs/heads/${branch}; then
    git branch --track ${branch} origin/${branch}
  fi
done
