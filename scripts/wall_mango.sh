#!/usr/bin/env bash

while true; do
	randImage=$(fd . $HOME/wall/ --type file | shuf -n 1)
	awww img "$randImage" --transition-type center --transition-fps 60 --transition-step 90
	sleep 600
done
