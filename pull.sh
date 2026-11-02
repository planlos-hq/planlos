#!/usr/bin/env bash
# Pull (fast-forward only) the current branch of every repo.
set -euo pipefail
# shellcheck source=repos.sh
source "$(dirname "$0")/repos.sh"

for repo in planlos "${REPOS[@]}"; do
  dir="$ROOT/$repo"
  [[ $repo == planlos ]] && dir="$ROOT"
  [[ -d "$dir" ]] || continue
  echo "== $repo"
  git -C "$dir" pull --ff-only || echo "!! $repo: pull failed"
done
