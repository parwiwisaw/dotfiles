#!/bin/sh
# Symlink dotfiles into $HOME. Idempotent; backs up any real file it replaces.
# Zero dependencies beyond POSIX sh — runs on macOS, Linux, and locked-down
# machines where installing a dotfile manager isn't an option.
set -eu

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
BACKUP_SUFFIX=".pre-dotfiles.$(date +%Y%m%d%H%M%S)"

# package-relative source -> $HOME-relative target
FILES="
zsh/.zshrc:.zshrc
zsh/.zprofile:.zprofile
zsh/.zshenv:.zshenv
starship/.config/starship.toml:.config/starship.toml
git/.gitconfig:.gitconfig
git/.gitignore_global:.gitignore_global
"

link() {
    src="$DOTFILES/$1"
    dst="$HOME/$2"
    mkdir -p "$(dirname "$dst")"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        echo "  ok      $2"
        return
    fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        mv "$dst" "$dst$BACKUP_SUFFIX"
        echo "  backup  $2 -> $2$BACKUP_SUFFIX"
    fi
    ln -s "$src" "$dst"
    echo "  link    $2 -> $1"
}

echo "Linking from $DOTFILES:"
for pair in $FILES; do
    link "${pair%%:*}" "${pair#*:}"
done

# Seed the machine-local layer if absent (never overwritten, never tracked)
if [ ! -e "$HOME/.zshrc.local" ] && [ -f "$DOTFILES/local/.zshrc.local.example" ]; then
    cp "$DOTFILES/local/.zshrc.local.example" "$HOME/.zshrc.local"
    echo "  seed    .zshrc.local (edit me: prompt label, work config)"
fi
if [ ! -e "$HOME/.gitconfig.local" ]; then
    printf '[user]\n\tname = CHANGE_ME\n\temail = CHANGE_ME\n' > "$HOME/.gitconfig.local"
    echo "  seed    .gitconfig.local (set your git identity)"
fi

# --- Packages ---------------------------------------------------------------
# Make `git pull && ./install.sh` a complete upsert: links AND packages.
# brew bundle / apt are idempotent — already-installed packages are skipped.
# Skip with: SKIP_PACKAGES=1 ./install.sh
if [ -z "${SKIP_PACKAGES:-}" ]; then
    # Find brew even under non-interactive ssh, where .zprofile hasn't run
    BREW=""
    for b in "$(command -v brew 2>/dev/null)" /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
        [ -n "$b" ] && [ -x "$b" ] && BREW="$b" && break
    done
    if [ -n "$BREW" ] && [ -f "$DOTFILES/Brewfile" ]; then
        echo "Packages (brew bundle):"
        "$BREW" bundle --file "$DOTFILES/Brewfile" | sed 's/^/  /'
    elif command -v apt-get >/dev/null 2>&1 && [ -f "$DOTFILES/packages.linux" ]; then
        pkgs=$(grep -v '^#' "$DOTFILES/packages.linux" | xargs)
        if sudo -n true 2>/dev/null; then
            echo "Packages (apt):"
            # shellcheck disable=SC2086
            sudo apt-get install -y -qq $pkgs >/dev/null && echo "  installed: $pkgs"
        else
            echo "Packages: sudo needs a password — run yourself:"
            echo "  sudo apt-get install -y $pkgs"
        fi
    fi
fi

echo "Done. Open a new shell."
