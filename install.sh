#!/usr/bin/env bash
# Installs the `envkeep` CLI onto your PATH.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
dest="${1:-/usr/local/bin}"

# dependency check
if ! command -v age >/dev/null || ! command -v age-keygen >/dev/null; then
  echo "Installing age (encryption backend)…"
  brew install age
fi

mkdir -p "$dest"
ln -sf "$here/envkeep" "$dest/envkeep"
echo "✓ Linked: $dest/envkeep -> $here/envkeep"
echo
echo "Now run:  envkeep init"
