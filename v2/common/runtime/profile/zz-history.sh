#!/usr/bin/env bash

# Persistent per-project shell history (within the mounted workspace)
HISTDIR="${CONTAINER_HISTORY_DIR:-/var/www/html/.container-history}"
HISTFILE="${HISTDIR}/bash_history"
mkdir -p "$HISTDIR" 2>/dev/null || true

export HISTFILE
export HISTSIZE="${HISTSIZE:-50000}"
export HISTFILESIZE="${HISTFILESIZE:-100000}"
export HISTCONTROL=ignoreboth:erasedups
export HISTIGNORE="ls:bg:fg:history:clear"

# Append, and sync on every prompt so parallel shells share history
shopt -s histappend 2>/dev/null || true
case "${PROMPT_COMMAND:-}" in
  *"history -a"*) ;; # already configured
  *) PROMPT_COMMAND="history -a; history -n${PROMPT_COMMAND:+; $PROMPT_COMMAND}";;
esac
