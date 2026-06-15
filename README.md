# 🔐 Envkeep

A small, secure place to keep your team's **ENV secrets** — managed through a
native **GUI** by humans, and read by a **CLI** during coding sessions (so you
can just tell an AI coding agent: *"grab `OPENAI_API_KEY` from envkeep"*).

- **Encrypted at rest** with [age](https://github.com/FiloSottile/age) — only
  ciphertext ever touches disk or git.
- **Decrypt-on-demand** by default — no plaintext is persisted anywhere.
- **Native macOS app** (Swift + WKWebView) *and* a zero-dependency CLI.
- **No server, no database, no pip packages.**

```
   GUI  (you)                         CLI  (Claude / coding sessions)
   Envkeep.app                        envkeep get OPENAI_API_KEY
        │                                       │
        ▼                                       ▼
  ┌───────────────┐                    ┌──────────────────┐
  │  vault.age    │   age-encrypted    │  envkeep get …    │
  │ (source of    │ ◀───────────────▶  │  decrypts one     │
  │  truth, in a  │   to each member   │  value on demand  │
  │  private repo)│                    └──────────────────┘
  └───────────────┘
```

## How it works

* **Source of truth** — `vault.age`, an age-encrypted JSON file encrypted to the
  public key of every teammate in `recipients.txt`. Store it in a private git
  repo or any synced folder; the host only ever sees ciphertext.
* **Your private key** lives only at `~/.config/envkeep/identity.txt`
  (`chmod 600`) and is **never** committed.
* **Reads decrypt on demand.** Optionally enable a macOS-Keychain cache for
  speed (`envkeep config cache keychain`); `envkeep lock` purges it.
* **Audit log** — every read/write is appended (names only, never values) to
  `~/.config/envkeep/access.log`.

## Install

```bash
./install.sh            # symlinks `envkeep` onto your PATH, installs age
envkeep init            # makes your key, vault dir, recipients entry
```

Build the native app (optional, macOS):

```bash
./build-app.sh          # produces Envkeep.app
open Envkeep.app        # or copy it to /Applications
```

## Daily use

### You (GUI)
```bash
open Envkeep.app        # add / edit / reveal / copy / delete
envkeep gui             # …or the same UI in your browser
```
Press **⌘K** for the command palette; `n` new, `/` search, `l` lock.

### Claude / a coding session (CLI)
```bash
envkeep list                       # names only, no values
envkeep get OPENAI_API_KEY         # prints just that one value
export OPENAI_API_KEY=$(envkeep get OPENAI_API_KEY)

envkeep env my-app                 # export lines for a whole project
eval "$(envkeep env my-app)"       # load all of my-app's vars at once
envkeep env my-app --dotenv > .env # …or write a .env file
```

### Managing secrets from the terminal
```bash
envkeep set STRIPE_KEY             # prompts for the value (hidden input)
envkeep set my-app/STRIPE_KEY sk-… # organise under a project/folder
envkeep rm  my-app/STRIPE_KEY
envkeep folders                    # list projects
envkeep lock                       # purge any cached plaintext
envkeep config                     # view settings (cache, log)
envkeep log --tail 20              # recent access log
```

## Organising into projects

A secret's name can be a path: `project/KEY` (or deeper, `project/prod/KEY`).
The folder is just the prefix — so `envkeep env project` can dump a whole
project's variables, and the GUI groups secrets by project automatically.

## Sharing with a team

1. A teammate installs this, runs `envkeep init`, and sends you their **public**
   key: `envkeep pubkey` → `age1…` (safe to share).
2. You add them and re-encrypt for everyone: `envkeep add-member alice age1…`.
3. They point their vault dir at the shared repo and they're in.
   `envkeep members` lists who has access.

## Security notes

* Only **ciphertext** (`vault.age`) is ever stored or pushed. A stolen repo or
  laptop-at-rest does not expose secrets.
* **The CLI runs as you** — anything you can run, your coding agent can run, so
  it can read any secret. Prefer handing it the *name* (or `envkeep env`) and
  injecting via the environment rather than printing values into a transcript.
* Removing a member re-encrypts going forward — **rotate** any secrets they knew.
* Back up `identity.txt` (e.g. in a password manager); lose it and you lose
  access until a teammate re-adds your new key.
* This is a lightweight tool, **not** a replacement for HashiCorp Vault / an HSM.

## Requirements

macOS, `age` + `age-keygen` (`brew install age`), Python 3 (system Python is
fine). The native app additionally needs Xcode command-line tools (`swiftc`).

## License

[MIT](LICENSE)
