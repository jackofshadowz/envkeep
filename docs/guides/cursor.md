# Using Envkeep with Cursor

[Cursor](https://cursor.com)'s agent can run terminal commands, so it can pull secrets from
your Envkeep vault on demand instead of you pasting API keys into the chat.

The rule of thumb: **give the agent the secret's *name*; let it run `envkeep`.**

## Fetch one value

Point the agent at the vault in your message:

> The Stripe key is in **envkeep** as `my-app/STRIPE_KEY` — load it before running the script.

It runs:

```bash
export STRIPE_KEY="$(envkeep get my-app/STRIPE_KEY)"
```

`envkeep get` prints just the value (no trailing newline when piped), so it's safe inside
`$(...)`.

## Load a whole project

```bash
eval "$(envkeep env my-app)"          # export every my-app/* secret into the shell
envkeep env my-app --dotenv > .env    # or write a throwaway .env (add it to .gitignore)
```

## Tell every session where secrets live

Add a project rule so Cursor's agent always reaches for Envkeep. Create
`.cursor/rules/secrets.mdc`:

```md
---
description: Where secrets live
alwaysApply: true
---
Secrets are stored in **envkeep**, not in committed `.env` files.
To use one: `envkeep get <project>/<KEY>`, or load a project with
`eval "$(envkeep env <project>)"`. Never print secret values into the chat —
inject them through the environment of the command that needs them.
```

(Older Cursor versions use a single `.cursorrules` file at the repo root — the same text works there.)

## Keep secrets out of the chat

Have the agent run the command that *consumes* the key, rather than echoing it:

```bash
# good: the value flows through env, never into the conversation
STRIPE_KEY="$(envkeep get my-app/STRIPE_KEY)" node charge.js

# avoid: prints the secret into the transcript
envkeep get my-app/STRIPE_KEY
```

## Why this beats a committed `.env`

- Only **ciphertext** (`vault.age`) is ever stored or pushed — a leaked repo exposes nothing.
- The agent gets **one value at a time**, not your entire environment file.
- Every read is **logged by name** (never the value).
- Share with teammates by age public key; revoke and rotate in one command.

Full CLI reference: [README](https://github.com/jackofshadowz/envkeep#readme).
