#!/usr/bin/env sh
# Insert the current Lampshell terminal palette, then run the terminal command.
# Reads the OSC sequences written by services/ThemeService.qml.

cat ~/.local/state/lampshell/sequences.txt 2>/dev/null

exec "$@"
