#!/usr/bin/env bash
# Clone all planlos repos (except .github) into this folder.
set -euo pipefail
# shellcheck source=repos.sh
source "$(dirname "$0")/repos.sh"

for repo in "${REPOS[@]}"; do
  if [[ -d "$ROOT/$repo" ]]; then
    echo "== $repo: already there"
  else
    git clone "$ORG/$repo.git" "$ROOT/$repo"
  fi
done
