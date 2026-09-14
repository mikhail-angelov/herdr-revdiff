#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -n "${REVDIFF_BIN:-}" ] && [ -x "$REVDIFF_BIN" ]; then
  revdiff="$REVDIFF_BIN"
elif [ -x "$SCRIPT_DIR/revdiff" ]; then
  revdiff="$SCRIPT_DIR/revdiff"
elif command -v revdiff >/dev/null 2>&1; then
  revdiff="$(command -v revdiff)"
else
  printf 'herdr-revdiff: revdiff is not installed; reinstall the plugin or add revdiff to PATH\n' >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  printf 'herdr-revdiff: current directory is not a Git repository\n' >&2
  exit 1
}
cd "$repo_root"

current_branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
default_ref="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"

if [ -z "$default_ref" ]; then
  for candidate in origin/main origin/master main master; do
    if git rev-parse --verify --quiet "${candidate}^{commit}" >/dev/null; then
      default_ref="$candidate"
      break
    fi
  done
fi

default_branch="${default_ref#origin/}"
if [ -n "$default_ref" ] && [ -n "$current_branch" ] && [ "$current_branch" != "$default_branch" ]; then
  exec "$revdiff" "$default_ref" --untracked
fi

exec "$revdiff" --untracked
