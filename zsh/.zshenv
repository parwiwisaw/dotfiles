# Sourced by EVERY zsh, including non-interactive ones (`ssh host 'cmd'`,
# scp, cron) that never read .zprofile/.zshrc — so remote commands can find
# brew- and user-installed tools. Keep this file minimal and fast.
for _p in /opt/homebrew/bin /usr/local/bin /home/linuxbrew/.linuxbrew/bin "$HOME/.local/bin"; do
  if [ -d "$_p" ]; then
    case ":$PATH:" in
      *":$_p:"*) ;;
      *) PATH="$_p:$PATH" ;;
    esac
  fi
done
unset _p
export PATH

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
