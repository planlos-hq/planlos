#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
compose=("$@")
[[ ${#compose[@]} -gt 0 ]] || compose=(docker compose)

"${compose[@]}" down || echo "!! down reported errors (nothing running?)"
echo "== stopped"
