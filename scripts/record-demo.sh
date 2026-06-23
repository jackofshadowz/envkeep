#!/usr/bin/env bash
# Record docs/demo.gif with vhs, against a throwaway demo vault.
#
# Builds an isolated $HOME with a fresh Envkeep vault seeded with OBVIOUSLY-FAKE
# secrets, records docs/demo.tape, then cleans up. Your real vault, identity, and
# Keychain are never touched (the demo runs in decrypt-on-demand mode, so nothing
# is written to the login Keychain).
#
# Requires:  vhs (brew install vhs) · age · envkeep on PATH
set -euo pipefail

here="$(cd "$(dirname "$0")/.." && pwd)"
cd "$here"

command -v vhs >/dev/null   || { echo "error: vhs not found — install with: brew install vhs" >&2; exit 1; }
command -v age >/dev/null   || { echo "error: age not found — brew install age" >&2; exit 1; }
command -v envkeep >/dev/null || { echo "error: envkeep not on PATH" >&2; exit 1; }

# --- isolated demo home ---------------------------------------------------
demo="$(mktemp -d)"
cleanup(){ rm -rf "$demo"; }
trap cleanup EXIT

export HOME="$demo"                    # vhs inherits this; envkeep reads ~/.config/envkeep
vault="$demo/env-secrets-vault"

echo "Seeding a throwaway demo vault in $demo …"
envkeep init --vault-dir "$vault" >/dev/null 2>&1 <<< ""
envkeep config cache none >/dev/null   # decrypt-on-demand: no Keychain writes
envkeep config log on    >/dev/null

# Fake secrets — safe to show on screen.
envkeep set my-app/OPENAI_API_KEY  "sk-demo-Xa9f3Kd0PpNqWy7Vh2Lr8Tb"          >/dev/null
envkeep set my-app/STRIPE_KEY      "sk_test_demo_4eC39HqLyjWDarjtT1zd"        >/dev/null
envkeep set my-app/DATABASE_URL    "postgres://demo:demo@localhost:5432/app"  >/dev/null

# Metadata that travels with a secret (the feature we want to show off).
envkeep note  my-app/STRIPE_KEY "rotate quarterly · owned by #payments"  >/dev/null
envkeep field my-app/STRIPE_KEY "USERNAME=ops@acme.io"                   >/dev/null
envkeep field my-app/STRIPE_KEY "URL=https://dashboard.stripe.com"       >/dev/null

# warm the audit log a little so `log --tail` has content
envkeep get my-app/OPENAI_API_KEY >/dev/null

echo "Recording docs/demo.gif …"
vhs docs/demo.tape

echo "✓ Wrote docs/demo.gif"
