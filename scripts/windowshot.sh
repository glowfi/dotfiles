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

# ---------- screen recording (wl-screenrec) ----------
RECORDDIR="${HOME}/Videos/ScreenRecords"
RECORDNAME="${RECORDDIR}/$(print_date).mp4"

# ask what to capture on the audio side before every recording
_audio_prompt() {
	case "$(printf 'no audio\nmicrophone\nsystem audio' | bemenu -l 3 -i -p 'Record audio?')" in
	"no audio") AUDIO="" ;;
	"microphone") AUDIO="--audio" ;;
	"system audio") AUDIO="--audio --audio-device $(pactl get-default-sink).monitor" ;;
	*) exit ;; # user pressed Esc
	esac
}

# any -v/-s invocation while a recording runs stops it instead (toggle)
_stop_if_recording() {
	if pgrep -x wl-screenrec >/dev/null 2>&1; then
		pkill -INT -x wl-screenrec # SIGINT finalizes the file cleanly
		notify-send "screen recording stopped"
		exit 0
	fi
}
record_region() {
	_stop_if_recording
	mkdir -p "${RECORDDIR}"
	geom="$(slurp)" || exit 1 # user pressed Esc
	_audio_prompt
	notify-send "recording region -> ${RECORDNAME}"
	# shellcheck disable=SC2086 -- AUDIO is intentionally word-split
	exec wl-screenrec $AUDIO -g "$geom" -f "${RECORDNAME}"
}
record_root() {
	_stop_if_recording
	mkdir -p "${RECORDDIR}"
	_audio_prompt
	notify-send "recording screen -> ${RECORDNAME}"
	# shellcheck disable=SC2086 -- AUDIO is intentionally word-split
	exec wl-screenrec $AUDIO -f "${RECORDNAME}"
}
# -----------------------------------------------------

prompter() {
	case "$(printf 'a selected area\nfull screen\nrecord a selected area\nrecord full screen\nstop recording' | bemenu -l 6 -i -p 'Screenshot which area?')" in
	"a selected area") region ;;
	"full screen") root ;;
	"record a selected area") record_region ;;
	"record full screen") record_root ;;
	"stop recording") _stop_if_recording ;;
	*) exit ;;
	esac
}
while getopts cwrvs o; do
	case "$o" in
	c) region ;;
	r) root ;;
	v) record_root ;;
	s) record_region ;;
	\?) printf 'Invalid option: -%s\n' "${o}" && exit 1 ;;
	esac
done
prompter
