# shellcheck shell=bash disable=SC2034
# Shared by the scripts: repos are cloned into this folder (gitignored)
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORG="git@github.com:planlos-hq"
REPOS=(planlos-db planlos-server planlos-web planlos-openapi planlos-docs)
