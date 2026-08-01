#!/usr/bin/env bash

ART="$HOME/.config/screensaver.txt"
[ -f "$ART" ] || figlet -f slant "ARCH" >"$ART"

EFFECTS=(beams binarypath bubbles burn crumble decrypt errorcorrect
	expand fireworks matrix orbittingvolley pour print rain
	randomsequence rings scattered slide spotlights spray swarm waves)

cleanup() {
	[ -n "$pid" ] && kill "$pid" 2>/dev/null
	exit 0
}
trap cleanup INT TERM

while true; do
	fx=${EFFECTS[RANDOM % ${#EFFECTS[@]}]}
	# animation in background, keyboard left free for us
	tte -i "$ART" --frame-rate 60 --canvas-width 0 --canvas-height 0 \
		--anchor-canvas c --anchor-text c "$fx" </dev/null &
	pid=$!

	# watch for Q while this effect plays
	while kill -0 "$pid" 2>/dev/null; do
		if read -rsn1 -t 0.2 key; then
			[[ "$key" == [qQ] ]] && cleanup
		fi
	done
	sleep 1
done
