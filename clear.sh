#!/usr/bin/env bash
# Delete all cloned repos (not the planlos repo itself) after yes
set -euo pipefail
# shellcheck source=repos.sh
source "$(dirname "$0")/repos.sh"

found=()
for repo in "${REPOS[@]}"; do
  dir="$ROOT/$repo"
  [[ -d "$dir" && ! -L "$dir" ]] || continue
  found+=("$repo")
  note=""
  if git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
    [[ -z "$(git -C "$dir" status --porcelain)" ]] || note+=" [UNCOMMITTED CHANGES]"
    [[ -z "$(git -C "$dir" log --branches --not --remotes --oneline)" ]] || note+=" [UNPUSHED COMMITS]"
  fi
  echo "== $repo$note"
done

if [[ ${#found[@]} -eq 0 ]]; then
  echo "== nothing to clear"
  exit 0
fi

read -r -p "Delete ${#found[@]} repo(s) from $ROOT? Type yes/ja: " answer
case "$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')" in
yes | ja) ;;
*)
  echo "== aborted"
  exit 1
  ;;
esac

for repo in "${found[@]}"; do
  rm -rf -- "${ROOT:?}/$repo"
  echo "== $repo: deleted"
done
