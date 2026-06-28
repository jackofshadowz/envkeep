# Envkeep demo — a reproducible terminal GIF, recorded with vhs (https://github.com/charmbracelet/vhs)
#
#   ./scripts/record-demo.sh      # sets up an isolated demo vault, then runs `vhs` on this tape
#
# Do not run `vhs docs/demo.tape` directly — it expects the demo vault that
# record-demo.sh seeds under an isolated $HOME (so your real vault is never touched).

Output docs/demo.gif

Require envkeep

Set Shell "bash"
Set FontSize 20
Set Width 1280
Set Height 600
Set Padding 26
Set Theme "Catppuccin Mocha"
Set TypingSpeed 45ms
Set PlaybackSpeed 1.0

# --- clean prompt (hidden setup) ---
Hide
Type `export PS1="\033[38;5;120m❯\033[0m "` Enter
Type "clear" Enter
Show

Sleep 700ms
Type "# your agent grabs one value, on demand" Sleep 450ms Enter
Sleep 350ms
Type "envkeep get my-app/OPENAI_API_KEY" Sleep 350ms Enter
Sleep 1300ms

Type "# load a whole project into the shell" Enter
Type `eval "$(envkeep env my-app)"` Sleep 300ms Enter
Type "printenv STRIPE_KEY DATABASE_URL" Sleep 300ms Enter
Sleep 1500ms

Type "# notes & extra fields ride along with it" Enter
Type "envkeep note my-app/STRIPE_KEY" Sleep 250ms Enter
Sleep 1000ms
Type "envkeep field my-app/STRIPE_KEY" Sleep 250ms Enter
Sleep 1500ms

Type "# the audit log keeps names, never values" Enter
Type "envkeep log --tail 4" Sleep 250ms Enter
Sleep 2600ms
