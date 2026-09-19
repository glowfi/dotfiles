#!/usr/bin/env bash

set -euo pipefail
MENU=(bemenu -l 10 -p "📋 Clip:")

if [[ -n ${WAYLAND_DISPLAY:-} ]]; then
	paste() { wl-paste --no-newline; }
	copy() { wl-copy; }
	watch() { exec wl-paste --watch cliphist store; }
else
	paste() { xclip -selection clipboard -o; }
	copy() { xclip -selection clipboard; }
	watch() { while clipnotify; do paste | cliphist store; done; }
fi

case ${1:-menu} in
watch) watch ;;
save) paste | cliphist store ;;
clear) cliphist wipe ;;
del)
	sel=$(cliphist list | "${MENU[@]}") || exit 0
	cliphist delete <<<"$sel"
	;;
*)
	sel=$(cliphist list | "${MENU[@]}") || exit 0
	cliphist decode <<<"$sel" | copy
	;;
esac
