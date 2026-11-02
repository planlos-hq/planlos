#!/usr/bin/env bash
# Fill the database of the running stack with fictional test data (testdata.sql).
# Refuses when the database already has rooms, lecturers or courses.
# Usage: ./testdata.sh [compose command, default: docker compose], e.g. ./testdata.sh podman-compose
set -euo pipefail
cd "$(dirname "$0")"
compose=("$@")
[[ ${#compose[@]} -gt 0 ]] || compose=(docker compose)

for _ in {1..30}; do
  "${compose[@]}" exec -T db pg_isready -U planlos -d planlos >/dev/null 2>&1 && break
  sleep 1
done
"${compose[@]}" exec -T db psql -q -U planlos -d planlos <testdata.sql
echo "== Testdaten eingefügt"
