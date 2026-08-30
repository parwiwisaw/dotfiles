# dotfiles

Portable shell configuration: zsh (fast startup — lazy nvm, cached compinit),
starship prompt, git. Works on macOS (arm64/Intel) and Linux; degrades
gracefully when optional tools are missing.

## Install

```sh
git clone <this-repo> ~/dotfiles
~/dotfiles/install.sh
```

`install.sh` symlinks configs into `$HOME`, backing up anything it replaces.
It has no dependencies beyond POSIX sh. Re-running is safe.

Packages (optional): `brew bundle --file ~/dotfiles/Brewfile` on macOS, or
`xargs -a ~/dotfiles/packages.linux sudo apt install -y` on Debian/Ubuntu.

## Layout

One directory per application, mirroring `$HOME`:

```
zsh/        .zshrc .zprofile .zshenv
starship/   .config/starship.toml
git/        .gitconfig .gitignore_global
local/      .zshrc.local.example   (template for the untracked local layer)
```

## Local layer

Machine-specific and private config never lives in this repo:

- `~/.zshrc.local` — prompt host label, work proxies, anything private.
  Sourced at the end of `.zshrc`; seeded from the example on first install.
- `~/.gitconfig.local` — git identity, pulled in via `[include]`.

Both are gitignored. A fresh machine refuses `git commit` until you set an
identity — that is deliberate.

## Prompt host label

The prompt shows `$PROMPT_HOST` (set in `~/.zshrc.local`), falling back to
the short hostname. Override per-shell with `PROMPT_HOST=X zsh`.
