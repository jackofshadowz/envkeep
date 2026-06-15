<div align="center">

<img src="app/icon.png" width="116" alt="Envkeep logo" />

# Envkeep

**A secure, age-encrypted home for your team's ENV secrets — a native macOS app for humans, a CLI for your AI coding agents.**

[![CI](https://github.com/jackofshadowz/envkeep/actions/workflows/ci.yml/badge.svg)](https://github.com/jackofshadowz/envkeep/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-7fee64.svg)](LICENSE)
![Platform: macOS](https://img.shields.io/badge/platform-macOS-1b1b1f.svg)
![Encryption: age](https://img.shields.io/badge/encryption-age-16341d.svg)
![pip deps: 0](https://img.shields.io/badge/pip%20deps-0-2ea043.svg)
![PRs welcome](https://img.shields.io/badge/PRs-welcome-7fee64.svg)

<br/>

<img src="docs/screenshot.png" width="840" alt="Envkeep app" />

</div>

---

So you can just tell your coding agent:

> *"the OpenAI key is in **envkeep** — grab `my-app/OPENAI_API_KEY`."*

…and it runs `envkeep get my-app/OPENAI_API_KEY`, pulling exactly one value on demand. No secret pasted into chat, no `.env` lying around, nothing in plaintext at rest.

## ✨ Features

| | |
|---|---|
| 🔐 **Encrypted at rest** | An [age](https://github.com/FiloSottile/age)-encrypted `vault.age` — only ciphertext ever hits disk or git. |
| 🖥️ **Native macOS app** | A real Swift / WKWebView window (not a browser tab) with its own Dock icon and menus. |
| ⌨️ **CLI for agents** | `envkeep get NAME` prints one value; `envkeep env project` loads a whole project. |
| 🗂️ **Projects & folders** | Organise secrets as `project/KEY`; the GUI groups them, the CLI dumps them. |
| 🧭 **Command palette** | ⌘K to jump to any project, secret, or action. Plus `n`, `/`, `l` shortcuts. |
| ⛔ **Decrypt-on-demand** | No plaintext cache by default; optional Keychain cache + one-click **Lock**. |
| 📥 **Import** | `envkeep import ./my-app` scans `.env` files and pulls them in (dry-run first). |
| 📜 **Audit log** | Every read/write is logged — names only, never values. |
| 👥 **Team-ready** | Share the encrypted vault via a private git repo; add members by public key. |
| 🪶 **Zero dependencies** | Pure Python 3 stdlib + `age`. No pip, no server, no database. |

## 🚀 Quickstart

**Homebrew (recommended):**

```bash
brew install jackofshadowz/tap/envkeep
envkeep init          # creates your key, vault, and recipients entry
```

**From source** (also builds the native app):

```bash
git clone https://github.com/jackofshadowz/envkeep.git
cd envkeep
./install.sh          # symlinks `envkeep` onto your PATH, installs age via brew
envkeep init
./build-app.sh && open Envkeep.app    # optional native macOS app
```

> Prefer the app? Download `Envkeep.app` from the
> [latest release](https://github.com/jackofshadowz/envkeep/releases/latest).

Add a secret, then read it in a coding session:

```bash
envkeep set my-app/OPENAI_API_KEY      # hidden prompt; or pass inline
envkeep get my-app/OPENAI_API_KEY      # prints just the value
eval "$(envkeep env my-app)"           # load the whole project into your shell
```

## 🧠 How it works

```
   GUI  (you)                          CLI  (Claude / coding sessions)
   Envkeep.app                         envkeep get my-app/OPENAI_API_KEY
        │                                        │
        ▼                                        ▼
  ┌────────────────┐                   ┌───────────────────────┐
  │   vault.age    │   age-encrypted   │  decrypts ONE value   │
  │  (source of    │ ◀───────────────▶ │  on demand — nothing  │
  │  truth, in a   │   to each member  │  persisted in plain   │
  │  private repo) │                   └───────────────────────┘
  └────────────────┘
```

* **Source of truth** — `vault.age`, encrypted to every teammate's age public key (`recipients.txt`). The git host only ever sees ciphertext.
* **Your private key** lives at `~/.config/envkeep/identity.txt` (`chmod 600`), never committed.
* **Reads decrypt on demand.** Enable a Keychain cache for speed (`envkeep config cache keychain`); `envkeep lock` purges it.

## 🛠️ CLI reference

```bash
envkeep set  my-app/STRIPE_KEY [value]   # add / update (hidden prompt if omitted)
envkeep get  my-app/STRIPE_KEY           # print one value
envkeep list [project]                   # names only
envkeep folders                          # list projects
envkeep env  my-app [--dotenv]           # export lines (or .env format)
envkeep import ./path [--apply]          # scan .env files (dry-run by default)
envkeep rm   my-app/STRIPE_KEY
envkeep lock                             # purge cached plaintext
envkeep config [cache keychain|none] [log on|off]
envkeep log [--tail N]                   # access log
envkeep pubkey | members | add-member alice age1…
envkeep gui                              # the same UI in your browser
```

GUI shortcuts: **⌘K** palette · **n** new · **/** search · **l** lock · **Esc** close · **⌘↵** save.

## 👥 Sharing with a team

1. A teammate runs `envkeep init` and sends you `envkeep pubkey` → `age1…`.
2. You run `envkeep add-member alice age1…` (re-encrypts the vault for everyone).
3. They point their vault dir at the shared private repo. `envkeep members` lists access.

## 🔒 Security

* Only **ciphertext** is ever stored or pushed — a stolen repo/laptop-at-rest exposes nothing.
* **The CLI runs as you**, so your coding agent can read any secret it's told to. Prefer handing it the *name* (or `envkeep env`) and injecting via the environment rather than printing values into a transcript.
* Removing a member re-encrypts going forward — **rotate** anything they knew.
* Back up `identity.txt` (e.g. a password manager); lose it and you lose access until re-added.
* Lightweight by design — **not** a replacement for HashiCorp Vault / an HSM.

## 📦 Requirements

macOS · `age` + `age-keygen` (`brew install age`) · Python 3 (system Python is fine) · Xcode CLT (`swiftc`) for the native app.

## 📄 License

[MIT](LICENSE) © 2026 Jack Baum
