#!/usr/bin/env sh

cat ~/.local/state/lampshell/sequences.txt 2>/dev/null

exec "$@"
