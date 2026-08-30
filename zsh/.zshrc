# Git aliases
alias g='git'

# Branch
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'

# Commit
alias gc='git commit -v'
alias gca='git commit -v -a'
alias gcam='git commit -a -m'
alias gcmsg='git commit -m'

# Checkout
alias gco='git checkout'
alias gcb='git checkout -b'
alias gcm='git checkout main'

# Diff
alias gd='git diff'
alias gdw='git diff --word-diff'
alias gdca='git diff --cached'

# Fetch
alias gf='git fetch'
alias gfa='git fetch --all --prune'

# Pull
alias gl='git pull'
alias gpr='git pull --rebase'

# Push
alias gp='git push'
alias gpd='git push --dry-run'
alias gpf='git push --force-with-lease'

# Status
alias gst='git status'
alias gss='git status -s'

# Add
alias ga='git add'
alias gaa='git add --all'
alias gau='git add --update'

# Log
alias glg='git log --stat'
alias glgp='git log --stat -p'
alias glgg='git log --graph'
alias gloga='git log --oneline --decorate --graph --all'

# Reset
alias grh='git reset'
alias grhh='git reset --hard'

# Stash
alias gsta='git stash save'
alias gstp='git stash pop'
alias gstc='git stash clear'

# Keep PATH free of duplicates no matter how many times entries get prepended
# (nested shells, tmux, direnv). Must come before the PATH edits below.
typeset -U path PATH

export PATH="$HOME/.local/bin:$PATH"

# LM Studio CLI (only present on some machines)
[ -d "$HOME/.lmstudio/bin" ] && export PATH="$PATH:$HOME/.lmstudio/bin"

# pnpm — home location differs per OS
if [ -d "$HOME/Library/pnpm" ]; then
  export PNPM_HOME="$HOME/Library/pnpm"          # macOS
elif [ -d "$HOME/.local/share/pnpm" ]; then
  export PNPM_HOME="$HOME/.local/share/pnpm"     # Linux
fi
# Prepend unconditionally: typeset -U keeps the first occurrence, so this both
# dedupes and guarantees front position even when a login shell's path_helper
# has demoted an inherited entry to the tail (tmux, nested shells).
[ -n "${PNPM_HOME:-}" ] && export PATH="$PNPM_HOME:$PATH"

# nvm: put the default node on PATH directly, and only source nvm.sh on first
# use of `nvm`. Sourcing it eagerly costs ~620ms per shell.
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/alias/default" ]; then
  _nvm_default="$(<"$NVM_DIR/alias/default")"
  _nvm_bin="$NVM_DIR/versions/node/v${_nvm_default#v}/bin"
  # Unconditional prepend; typeset -U dedupes keeping front position (see above)
  [ -d "$_nvm_bin" ] && export PATH="$_nvm_bin:$PATH"
  unset _nvm_default _nvm_bin
fi

nvm() {
  unfunction nvm
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  nvm "$@"
}

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# --- Zsh plugins ---

# Homebrew prefix: HOMEBREW_PREFIX is set by `brew shellenv` in .zprofile, but
# that only runs for login shells — fall back to the standard locations.
_bp=${HOMEBREW_PREFIX:-/opt/homebrew}
[ -d "$_bp" ] || _bp=/usr/local
[ -d "$_bp" ] || _bp=/home/linuxbrew/.linuxbrew

# Completions (must be before compinit)
[ -d "$_bp/share/zsh-completions" ] && FPATH=$_bp/share/zsh-completions:$FPATH

autoload -Uz compinit
# Only run the slow fpath security audit when the dump is missing or older than
# a day; otherwise trust it (-C). Keep the dump zcompile'd so it loads as
# bytecode. Run `compinit-refresh` after installing new completions.
_zdump=${ZDOTDIR:-$HOME}/.zcompdump
_zdump_stale=( $_zdump(N.mh+24) )
if [[ ! -f $_zdump ]] || (( ${#_zdump_stale} )); then
  compinit -d $_zdump
  zcompile -R -- $_zdump
else
  compinit -C -d $_zdump
fi
unset _zdump _zdump_stale

# Force a full completion rebuild (use after installing new completions)
compinit-refresh() {
  local d=${ZDOTDIR:-$HOME}/.zcompdump
  rm -f $d $d.zwc
  autoload -Uz compinit && compinit -d $d && zcompile -R -- $d
  print "completions rebuilt"
}

# Autosuggestions / syntax highlighting: check brew prefix first, then the
# apt install locations. Missing plugins degrade silently.
for _f in "$_bp/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
          /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh; do
  [ -r "$_f" ] && source "$_f" && break
done
for _f in "$_bp/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
          /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [ -r "$_f" ] && source "$_f" && break
done
unset _f _bp

# fzf keybindings (Ctrl+R). `--zsh` needs fzf >= 0.48; skip quietly on older.
if command -v fzf >/dev/null && fzf --zsh >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

# zoxide — smarter cd (z <fragment>); silently absent if not installed
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# Starship prompt
command -v starship >/dev/null && eval "$(starship init zsh)"

# iTerm2 shell integration (macOS only; absent elsewhere)
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Antigravity (only present on some machines)
[ -d "$HOME/.antigravity/antigravity/bin" ] && export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# --- Machine-local overrides (not tracked in git) --------------------------
# Identity, host labels, work-specific config. See .zshrc.local.example.
[ -r "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# Prompt host label: .zshrc.local sets PROMPT_HOST for known machines;
# fall back to the short hostname. Rendered by starship's env_var module.
: ${PROMPT_HOST:=${HOST%%.*}}
export PROMPT_HOST
