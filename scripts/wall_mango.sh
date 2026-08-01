#!/usr/bin/env bash

randImage=$(fd . $HOME/wall/ --type file | shuf -n 1)
awww img "$randImage" --transition-type wipe --transition-fps 60 --transition-step 90
