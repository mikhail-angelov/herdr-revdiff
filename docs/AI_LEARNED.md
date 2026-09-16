## 2026-09-16 — Focus plugin tabs through the public tab API

### Goal

Ensure a plugin action that opens or reuses a tab also moves attached Herdr clients to that tab.

### Golden path

1. Open the plugin pane with `herdr plugin pane open --no-focus` and keep its JSON response.
2. Read `.result.plugin_pane.pane.tab_id` from the response.
3. Run `herdr tab focus <tab_id>`.
4. When reusing a pane, take its `tab_id` from `herdr pane list` and focus that tab directly.

### Verification

On Herdr 0.9.0, invoking `herdr-revdiff.open` produced a successful `plugin.pane.open` followed by a successful public `tab.focus` request for the created tab.

### Failure pattern avoided

`plugin pane open --focus` and `plugin pane focus` can update server focus without moving an attached client's viewport on Herdr 0.9.0.

### Ruled-out approaches

- Tried relying on `plugin pane open --focus`; the server logged the new tab as focused, but the attached client stayed on the old tab.
- Considered an immediate `plugin pane focus`; it uses the same plugin-specific focus path and does not address client viewport propagation.

### Notes

The public `tab focus` API is the compatibility path until Herdr propagates plugin-pane focus requests to attached clients.
