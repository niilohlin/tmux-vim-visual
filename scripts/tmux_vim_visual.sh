#!/usr/bin/env sh

set -e
set -o pipefail

TMPFILE=$(mktemp).tmux_pane.out
VIM_COMMAND=$(command -v nvim || command -v vim)

# -J: join lines, removes soft wraps
# -p: output to stdout
# -S: start at the beginning of the history
tmux capture-pane -J -pS - > $TMPFILE

# -P: print window id
# -d: open window in the background
# -R: read-only mode
WINDOW_ID=$(tmux new-window -P -d "$VIM_COMMAND -R -c 'norm G' -c 'set laststatus=0' -c 'set noshowcmd' -c 'set noruler' -c 'set noshowmode' -c 'set cmdheight=0' $TMPFILE")

# -p: output to stdout
CURRENT_WINDOW_ID=$(tmux display-message -p '#{window_id}')

# -s: source window id
# -t: target window id
tmux swap-pane -s $WINDOW_ID -t $CURRENT_WINDOW_ID

# remain on exit makes it so that "pane-died" is triggered when the pane exits, without closing the pane
# and window.
tmux set-window-option -t $CURRENT_WINDOW_ID remain-on-exit on

tmux set-hook pane-died "run-shell '\
    tmux swap-pane -s $CURRENT_WINDOW_ID -t $WINDOW_ID;\
    tmux kill-window -t $WINDOW_ID;\
    tmux set-hook -u pane-died;\
    tmux set-window-option -t $CURRENT_WINDOW_ID remain-on-exit off;
    '"

