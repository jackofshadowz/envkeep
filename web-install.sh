#!/usr/bin/env bash
# One-line installer:
#   curl -fsSL https://raw.githubusercontent.com/jackofshadowz/envkeep/main/web-install.sh | bash
# Downloads the `envkeep` CLI (a single self-contained Python file) and ensures `age`.
set -euo pipefail

REPO="jackofshadowz/envkeep"
REF="${ENVKEEP_REF:-main}"
dest="${ENVKEEP_BIN:-$HOME/.local/bin}"

mkdir -p "$dest"
echo "Downloading envkeep ($REF)…"
curl -fsSL "https://raw.githubusercontent.com/$REPO/$REF/envkeep" -o "$dest/envkeep"
chmod +x "$dest/envkeep"
echo "✓ Installed: $dest/envkeep"

if ! command -v age >/dev/null 2>&1 || ! command -v age-keygen >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    echo "Installing age (encryption backend)…"
    brew install age
  else
    echo "⚠ Please install 'age' + 'age-keygen': https://github.com/FiloSottile/age"
  fi
fi

case ":$PATH:" in
  *":$dest:"*) ;;
  *) echo; echo "Add $dest to your PATH:"; echo "  export PATH=\"$dest:\$PATH\"";;
esac

echo
echo "Next:  envkeep init"
