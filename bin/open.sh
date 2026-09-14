#!/usr/bin/env bash
set -euo pipefail

readonly HERDR="${HERDR_BIN_PATH:-herdr}"
readonly PLUGIN_ID="${HERDR_PLUGIN_ID:-herdr-revdiff}"
readonly WORKSPACE_ID="${HERDR_WORKSPACE_ID:-}"
CONTEXT="${HERDR_PLUGIN_CONTEXT_JSON:-}"
[ -n "$CONTEXT" ] || CONTEXT='{}'
readonly CONTEXT

fail() {
  printf 'herdr-revdiff: %s\n' "$1" >&2
  exit 1
}

command -v jq >/dev/null 2>&1 || fail "jq is required"
[ -n "$WORKSPACE_ID" ] || fail "run this action from a Herdr workspace"

cwd="$(printf '%s' "$CONTEXT" | jq -r '.focused_pane_cwd // .workspace_cwd // empty')"
[ -n "$cwd" ] || fail "cannot determine the focused pane directory"
repo_root="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)" || fail "not a Git repository: $cwd"

panes_json="$("$HERDR" pane list --workspace "$WORKSPACE_ID")" || fail "cannot list panes in workspace $WORKSPACE_ID"

while IFS=$'\t' read -r pane_id pane_cwd; do
  [ -n "$pane_id" ] && [ -n "$pane_cwd" ] || continue
  pane_repo="$(git -C "$pane_cwd" rev-parse --show-toplevel 2>/dev/null || true)"
  [ "$pane_repo" = "$repo_root" ] || continue

  process_json="$("$HERDR" pane process-info --pane "$pane_id" 2>/dev/null || true)"
  if printf '%s' "$process_json" | jq -e '
    any(.result.process_info.foreground_processes[]?;
      ((.argv0 // (.argv[0] // "")) | split("/") | last) == "revdiff")
  ' >/dev/null 2>&1; then
    "$HERDR" plugin pane focus "$pane_id" >/dev/null
    exit 0
  fi
done < <(printf '%s' "$panes_json" |
  jq -r '.result.panes[]? | [(.pane_id // empty), (.foreground_cwd // .cwd // "")] | @tsv')

"$HERDR" plugin pane open \
  --plugin "$PLUGIN_ID" \
  --entrypoint revdiff \
  --placement tab \
  --workspace "$WORKSPACE_ID" \
  --cwd "$repo_root" \
  --focus >/dev/null
