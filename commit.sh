#!/usr/bin/env bash
# Commit all changes in every repo that has some, with the same message.
# Usage: ./commit.sh "message"
set -euo pipefail
# shellcheck source=repos.sh
source "$(dirname "$0")/repos.sh"
msg="${1:?usage: $0 \"commit message\"}"

for repo in planlos "${REPOS[@]}"; do
  dir="$ROOT/$repo"; [[ $repo == planlos ]] && dir="$ROOT"
  [[ -d "$dir" ]] || continue
  if [[ -z "$(git -C "$dir" status --porcelain)" ]]; then
    echo "== $repo: nothing to commit"
    continue
  fi
  echo "== $repo"
  git -C "$dir" add -A
  git -C "$dir" commit -m "$msg"
done
