# Using Envkeep with aider

[aider](https://aider.chat) pairs with you in the terminal — which means Envkeep fits in the
most natural way of all: you control the shell, and you feed aider only what it needs.

## Aider's own API keys

Aider itself needs a model API key (OpenAI, Anthropic, etc.). Pull it from Envkeep when you
launch, so the key lives in the process environment and never in a dotfile:

```bash
export OPENAI_API_KEY="$(envkeep get aider/OPENAI_API_KEY)"
aider

# or Anthropic
export ANTHROPIC_API_KEY="$(envkeep get aider/ANTHROPIC_API_KEY)"
aider --model sonnet
```

Wrap it in a shell function so it's one word:

```bash
# ~/.zshrc
aiderk() { ANTHROPIC_API_KEY="$(envkeep get aider/ANTHROPIC_API_KEY)" aider "$@"; }
```

The key is set only for that process and is gone when aider exits — nothing written to disk.

## Secrets for the project you're editing

When aider runs or tests your code and that code needs secrets, load the project's vars into
the shell *before* you start aider (or before you run the command from aider's prompt):

```bash
eval "$(envkeep env my-app)"     # export every my-app/* secret
aider
```

From inside aider you can run shell commands with `/run`:

```
/run eval "$(envkeep env my-app)" && pytest
```

## Don't paste keys into the chat

Aider sends your messages to the model, so treat the chat like a transcript: reference
secrets by **name**, never by value.

```bash
# good — value flows through the environment
STRIPE_KEY="$(envkeep get my-app/STRIPE_KEY)" python run.py

# avoid — the value ends up in scrollback and possibly the model context
envkeep get my-app/STRIPE_KEY
```

## Why Envkeep + aider works well

- You stay in control of the shell — aider only ever sees the **names** you mention.
- Only **ciphertext** is stored or pushed; a leaked repo exposes nothing.
- Reads are **audited by name** in `~/.config/envkeep/access.log` (never the value).
- Optional Keychain cache keeps repeated reads fast; `envkeep lock` purges it.

Full CLI reference: [README](https://github.com/jackofshadowz/envkeep#readme).
