#!/bin/sh

print_date() {
	d=$(date +%-d)
	case "$d" in
	11 | 12 | 13) suf="th" ;;
	*1) suf="st" ;;
	*2) suf="nd" ;;
	*3) suf="rd" ;;
	*) suf="th" ;;
	esac
	date "+${d}${suf}-%B-%Y-%H:%M:%S.%3N"
}

SCREENSHOTDIR="${HOME}/Pictures/ScreenShots"
SCREENSHOTNAME="${SCREENSHOTDIR}/$(print_date).png"
mkdir -p "${SCREENSHOTDIR}"

_end() {
	notify-send "screenshot name ${SCREENSHOTNAME}"
	wl-copy -t image/png <"${SCREENSHOTNAME}"
	exit 0
}

region() {
	geom="$(slurp)" || exit 1 # user pressed Esc
	grim -g "$geom" "${SCREENSHOTNAME}"
	_end
}

root() {
	grim "${SCREENSHOTNAME}"
	_end
}

prompter() {
	case "$(printf 'a selected area\nfull screen' | bemenu -l 6 -i -p 'Screenshot which area?')" in
	"a selected area") region ;;
	"full screen") root ;;
	*) exit ;;
	esac
}

while getopts cwr o; do
	case "$o" in
	c) region ;;
	r) root ;;
	\?) printf 'Invalid option: -%s\n' "${o}" && exit 1 ;;
	esac
done
prompter
