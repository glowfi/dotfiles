#!/usr/bin/env bash

# ============================================================================
# clipmenu - Simple clipboard selector using bemenu (X11/Wayland agnostic)
# ============================================================================

set -euo pipefail

HISTORY_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/clipboard_history.txt"
MAX_ENTRIES=50

# ----- Detect clipboard tool ------------------------------------------------
if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
	COPY="wl-copy"
	PASTE="wl-paste"
else
	COPY="xclip -selection clipboard"
	PASTE="xclip -selection clipboard -o"
fi

# ----- Functions ------------------------------------------------------------

# Get current clipboard content
get_clipboard() {
	eval "${PASTE}" 2>/dev/null || echo ""
}

# Copy to clipboard
set_clipboard() {
	eval "${COPY}" <<<"$1"
}

# Add entry to history (avoid duplicates, limit size)
add_to_history() {
	local entry="$1"
	[[ -z "$entry" ]] && return

	# Create file if missing
	touch "$HISTORY_FILE"

	# One-line version for storage (replace newlines with ␤)
	local oneline="${entry//$'\n'/␤}"

	# Remove duplicate if exists, then prepend
	grep -vxF "$oneline" "$HISTORY_FILE" 2>/dev/null | head -n $((MAX_ENTRIES - 1)) >"${HISTORY_FILE}.tmp" || true
	{
		echo "$oneline"
		cat "${HISTORY_FILE}.tmp"
	} >"$HISTORY_FILE"
	rm -f "${HISTORY_FILE}.tmp"
}

# Show menu and get selection
show_menu() {
	[[ ! -s "$HISTORY_FILE" ]] && {
		echo "No clipboard history." >&2
		exit 1
	}

	# Show in bemenu (truncate display to 80 chars)
	selected=$(cut -c1-80 "$HISTORY_FILE" | bemenu -l 10 -p "📋 Clip:")

	[[ -z "$selected" ]] && exit 0

	# Find full entry matching selection
	full_entry=$(grep -F "$selected" "$HISTORY_FILE" | head -1)

	# Restore newlines and copy
	restored="${full_entry//␤/$'\n'}"
	set_clipboard "$restored"

	echo "Copied: ${selected:0:50}..."
}

# ----- Main -----------------------------------------------------------------

case "${1:-menu}" in
save)
	# Call this to save current clipboard to history
	add_to_history "$(get_clipboard)"
	;;
menu | *)
	# Save current first, then show menu
	add_to_history "$(get_clipboard)"
	show_menu
	;;
esac
