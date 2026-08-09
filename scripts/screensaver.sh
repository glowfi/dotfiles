#!/usr/bin/env bash

ART="$HOME/.config/screensaver.txt"
[ -f "$ART" ] || figlet -f slant "ARCH" >"$ART"

EFFECTS=(beams binarypath bubbles burn crumble decrypt errorcorrect
	expand fireworks matrix orbittingvolley pour print rain
	randomsequence rings scattered slide spotlights spray swarm waves)

# gruvbox ramps: warm / green-aqua / purple-orange
RAMPS=(
	"fabd2f fe8019 fb4934"
	"b8bb26 8ec07c 83a598"
	"d3869b fb4934 fe8019"
)

cleanup() {
	[ -n "$pid" ] && kill "$pid" 2>/dev/null
	exit 0
}
trap cleanup INT TERM

while true; do
	fx=${EFFECTS[RANDOM % ${#EFFECTS[@]}]}
	ramp=(${RAMPS[RANDOM % ${#RAMPS[@]}]})

	# animation in background, keyboard left free for us
	tte -i "$ART" --frame-rate 60 --canvas-width 0 --canvas-height 0 \
		--anchor-canvas c --anchor-text c \
		--terminal-background-color 282828 \
		"$fx" --final-gradient-stops "${ramp[@]}" </dev/null &
	pid=$!

	# watch for Q while this effect plays
	while kill -0 "$pid" 2>/dev/null; do
		if read -rsn1 -t 0.2 key; then
			[[ "$key" == [qQ] ]] && cleanup
		fi
	done
	sleep 1
done
