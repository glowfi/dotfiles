#!/bin/sh

EFFECTS="beams binarypath bubbles burn crumble decrypt errorcorrect
expand fireworks matrix orbittingvolley pour print rain
randomsequence rings scattered slide spotlights spray swarm waves"

while true; do
	fx=$(printf '%s\n' $EFFECTS | shuf -n1)
	figlet -f slant "ARCH" | tte --frame-rate 60 \
		--canvas-width 0 --canvas-height 0 \
		--anchor-canvas c --anchor-text c "$fx"
	sleep 1
done
