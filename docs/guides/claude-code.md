# Using Envkeep with Claude Code

[Claude Code](https://claude.com/claude-code) runs shell commands on your behalf, so it can
fetch secrets the same way you would — without you ever pasting an API key into the chat.

The pattern: **tell Claude the *name* of the secret, let it run `envkeep`.**

## One value, on demand

In your prompt, just point at the vault:

> The OpenAI key is in **envkeep** — grab `my-app/OPENAI_API_KEY` when you need it.

Claude runs:

```bash
envkeep get my-app/OPENAI_API_KEY
```

`get` prints exactly one value to stdout with no decoration, so it's safe to capture:

```bash
export OPENAI_API_KEY="$(envkeep get my-app/OPENAI_API_KEY)"
```

## A whole project at once

To load every secret in a project into the environment for the command it's about to run:

```bash
eval "$(envkeep env my-app)"        # export INTO the current shell
envkeep env my-app --dotenv > .env  # …or write a throwaway .env (gitignore it)
```

`envkeep env my-app` emits `export KEY=...` lines for everything under the `my-app/`
folder — nothing is written to disk unless you ask for `--dotenv`.

## Keep keys out of the transcript

Prefer **injecting via the environment** over printing values. Instead of asking Claude to
"show me the key," tell it to run the command that *needs* the key:

```bash
# good — the value flows through the env, never into the chat log
OPENAI_API_KEY="$(envkeep get my-app/OPENAI_API_KEY)" python run.py

# avoid — this echoes the secret into the transcript
envkeep get my-app/OPENAI_API_KEY
```

## Make it a project convention

Add a line to your repo's `CLAUDE.md` so every session knows where secrets live:

```md
## Secrets
Secrets live in **envkeep**, not in `.env`. To use one, run
`envkeep get <project>/<KEY>` or load a project with `eval "$(envkeep env <project>)"`.
Never print secret values into the conversation — inject them via the environment.
```

## Allow the command without a prompt

If you want Claude Code to run `envkeep get`/`env` without asking each time, add them to your
allowlist in `.claude/settings.json`:

```json
{
  "permissions": {
    "allow": ["Bash(envkeep get:*)", "Bash(envkeep env:*)"]
  }
}
```

## Why this is safe(r)

- **Nothing in the transcript** — Claude calls `envkeep`, you don't paste keys.
- **Scoped** — hand it one secret or one project, not your entire `.env`.
- **Audited** — every read is logged by *name* (never the value) in `~/.config/envkeep/access.log`.
- **Honest caveat** — the CLI runs as *you*, so an agent you let run commands can read any
  secret it's pointed at. Point it at names, not your whole vault, and rotate anything that
  does end up in a log you don't control.

See the [README](https://github.com/jackofshadowz/envkeep#readme) for the full CLI reference.
