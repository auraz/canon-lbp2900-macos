#!/bin/sh
# macOS password dialog for `sudo -A` (used by the justfile because `!` in Claude Code has no terminal).
osascript -e 'display dialog "Password for sudo (Canon LBP2900 driver):" default answer "" with hidden answer with title "just"' -e 'text returned of result'
