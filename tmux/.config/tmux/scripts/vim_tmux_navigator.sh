#!/usr/bin/env bash
set -euo pipefail

TMUX_BIN="${TMUX_BIN:-tmux}"

is_vim_pane() {
  # Fast path: tmux knows the foreground command in the pane
  # Typical values: nvim, vim, vi, vimx, gvim, view
  local cmd
  cmd="$("$TMUX_BIN" display-message -p "#{pane_current_command}" 2>/dev/null || true)"
  case "$cmd" in
    vim|vi|nvim|vimx|gvim|view|vimdiff|nvimdiff) return 0 ;;
  esac

  # Optional: if you run vim inside something that masks pane_current_command
  # (e.g., some wrappers), you can expand this with ps-based detection.
  return 1
}

nav() {
  # $1: direction in tmux select-pane flags: L/D/U/R
  # If in Vim, send Ctrl-h/j/k/l to Vim so vim-tmux-navigator can handle it.
  local dir="${1:?missing dir}"
  if is_vim_pane; then
    case "$dir" in
      L) "$TMUX_BIN" send-keys C-h ;;
      D) "$TMUX_BIN" send-keys C-j ;;
      U) "$TMUX_BIN" send-keys C-k ;;
      R) "$TMUX_BIN" send-keys C-l ;;
      *) exit 2 ;;
    esac
  else
    "$TMUX_BIN" select-pane "-$dir"
  fi
}

install() {
  local self="$HOME/.config/tmux/scripts/vim_tmux_navigator.sh"

  # Optional: also support classic Ctrl-h/j/k/l (comment out if you don't want it)
  "$TMUX_BIN" bind-key -n C-h run-shell -b "$self nav L"
  "$TMUX_BIN" bind-key -n C-j run-shell -b "$self nav D"
  "$TMUX_BIN" bind-key -n C-k run-shell -b "$self nav U"
  "$TMUX_BIN" bind-key -n C-l run-shell -b "$self nav R"

  # Make it behave in copy-mode too (copy-mode tables don't fall back to root)
  "$TMUX_BIN" bind-key -T copy-mode     M-n select-pane -L
  "$TMUX_BIN" bind-key -T copy-mode     M-e select-pane -D
  "$TMUX_BIN" bind-key -T copy-mode     M-u select-pane -U
  "$TMUX_BIN" bind-key -T copy-mode     M-i select-pane -R
  "$TMUX_BIN" bind-key -T copy-mode-vi  M-n select-pane -L
  "$TMUX_BIN" bind-key -T copy-mode-vi  M-e select-pane -D
  "$TMUX_BIN" bind-key -T copy-mode-vi  M-u select-pane -U
  "$TMUX_BIN" bind-key -T copy-mode-vi  M-i select-pane -R

}

cmd="${1:-}"
shift || true
case "$cmd" in
  nav) nav "${1:?}" ;;
  install) install ;;
  *)
    echo "Usage: $0 install | nav {L|D|U|R}" >&2
    exit 1
    ;;
esac
