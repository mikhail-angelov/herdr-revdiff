#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TARGET="$SCRIPT_DIR/revdiff"
readonly RELEASE_API="https://api.github.com/repos/umputun/revdiff/releases/latest"

fail() {
  printf 'herdr-revdiff: %s\n' "$1" >&2
  exit 1
}

for tool in curl tar awk jq; do
  command -v "$tool" >/dev/null 2>&1 || fail "$tool is required to install revdiff"
done

case "$(uname -s)" in
Darwin) os="darwin" ;;
Linux) os="linux" ;;
*) fail "unsupported operating system: $(uname -s)" ;;
esac

case "$(uname -m)" in
x86_64 | amd64) arch="amd64" ;;
arm64 | aarch64) arch="arm64" ;;
*) fail "unsupported architecture: $(uname -m)" ;;
esac

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

curl -fsSL \
  -H 'Accept: application/vnd.github+json' \
  -H 'X-GitHub-Api-Version: 2022-11-28' \
  "$RELEASE_API" -o "$tmp_dir/release.json"

tag="$(jq -r '.tag_name // empty' "$tmp_dir/release.json")"
[ -n "$tag" ] || fail "GitHub did not report a latest revdiff release"
version="${tag#v}"
case "$version" in
'' | *[!0-9A-Za-z._-]*) fail "unsupported revdiff release tag: $tag" ;;
esac

archive="revdiff_${version}_${os}_${arch}.tar.gz"
asset="$(jq -c --arg name "$archive" 'first(.assets[]? | select(.name == $name)) // empty' "$tmp_dir/release.json")"
[ -n "$asset" ] || fail "release $tag has no asset named $archive"

url="$(printf '%s' "$asset" | jq -r '.browser_download_url // empty')"
[ -n "$url" ] || fail "asset $archive has no download URL"

expected="$(printf '%s' "$asset" | jq -r 'select((.digest // "") | startswith("sha256:")) | .digest | ltrimstr("sha256:")')"
[ -n "$expected" ] || fail "asset $archive has no sha256 digest published by GitHub"

curl -fsSL "$url" -o "$tmp_dir/$archive"

if command -v sha256sum >/dev/null 2>&1; then
  actual="$(sha256sum "$tmp_dir/$archive" | awk '{ print $1 }')"
elif command -v shasum >/dev/null 2>&1; then
  actual="$(shasum -a 256 "$tmp_dir/$archive" | awk '{ print $1 }')"
else
  fail "sha256sum or shasum is required"
fi

[ "$actual" = "$expected" ] || fail "checksum mismatch for $archive"

mkdir -p "$tmp_dir/unpacked"
tar -xzf "$tmp_dir/$archive" -C "$tmp_dir/unpacked"
binary="$(find "$tmp_dir/unpacked" -maxdepth 2 -type f -name revdiff -print -quit)"
[ -n "$binary" ] || fail "revdiff binary is missing from $archive"

install -m 0755 "$binary" "$TARGET"
printf 'herdr-revdiff: installed revdiff %s\n' "$tag"
