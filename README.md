# herdr-revdiff

Open [revdiff](https://github.com/umputun/revdiff) in a full-size Herdr tab with one keypress.

<img height="400" alt="image" src="https://github.com/user-attachments/assets/d16c34ad-3697-4a8f-94d1-a4b3988087c5" />


The scope is selected automatically:

- on the repository's default branch, review uncommitted changes against `HEAD`;
- on any other branch, review the branch and its uncommitted changes against the default branch;
- include untracked files in both modes.

The default branch is taken from `origin/HEAD`, falling back to the first of `origin/main`, `origin/master`, `main`, `master` that exists. On a detached `HEAD` only uncommitted changes are reviewed.

If revdiff is already open in the workspace **for the same repository**, the same key focuses that tab instead of opening another one.

revdiff is launched with `-o ./.review.md`: annotations added inside revdiff (`a` to annotate, `O` to flush) land in `.review.md` at the repository root. Mouse tracking stays enabled — wheel and click navigation work.

### Selecting text with the mouse

To select text, suspend mouse tracking with the `toggle_mouse` action: the terminal regains the mouse and plain drag selects text; pressing the key again restores wheel and click handling. The action has no default key — map it once in `~/.config/revdiff/keybindings`:

```sh
echo 'map m toggle_mouse' >> ~/.config/revdiff/keybindings
```

`toggle_mouse` landed in revdiff after v1.14.0. Until the next revdiff release ships, it is available only in builds from master; re-run `herdr plugin install` afterwards to update the bundled binary.

## Install

```sh
herdr plugin install mikhail-angelov/herdr-revdiff
```

Add the global Herdr keybinding to `~/.config/herdr/config.toml`:

```toml
[[keys.command]]
key = "prefix+r"
type = "plugin_action"
command = "herdr-revdiff.open"
description = "open revdiff"
```

Reload Herdr configuration:

```sh
herdr server reload-config
```

`prefix+r` is global inside Herdr: press the prefix (normally `Ctrl+B`), release it, then press `R`. It works in terminals that do not forward the Command modifier.

The GitHub installation downloads the latest revdiff release into the managed plugin directory and verifies the asset against the SHA-256 digest published by GitHub. It does not modify `~/.local/bin`.

Re-run the same `herdr plugin install` command to update both the plugin and its bundled revdiff.

## Local development

When revdiff is already on `PATH`:

```sh
herdr plugin link "$PWD"
```

To test the same plugin-local binary used by GitHub installs:

```sh
bash bin/ensure-revdiff.sh
herdr plugin link "$PWD"
```

Herdr does not run manifest build commands for locally linked plugins.

Set `REVDIFF_BIN` to an explicit executable to override binary lookup; otherwise the plugin uses `bin/revdiff` next to the scripts, then `revdiff` from `PATH`.

## Requirements

- Herdr 0.7.5 or newer;
- Git and jq;
- macOS or Linux on amd64 or arm64;
- curl, tar, and `shasum` or `sha256sum` during GitHub installation.

## License

[MIT](LICENSE)
