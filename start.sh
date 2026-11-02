#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
compose=("$@")
[[ ${#compose[@]} -gt 0 ]] || compose=(docker compose)

if [[ ! -f .env ]]; then
  echo "!! no .env found"
  if [[ -f .env.example ]]; then
    echo "!! create one from the template: cp .env.example .env"
  fi
fi

echo "== down"
"${compose[@]}" down || echo "!! down reported errors (nothing running?)"
echo "== up --build -d"
"${compose[@]}" up --build -d
