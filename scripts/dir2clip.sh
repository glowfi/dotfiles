#!/usr/bin/env bash
# clipdir.sh - copy path + content of files under a directory to clipboard
# usage: clipdir.sh <directory> [depth]

set -euo pipefail

DIR="${1:?usage: clipdir.sh <directory> [depth]}"
DEPTH="${2:-1}"

[ -d "$DIR" ] || {
	echo "not a directory: $DIR" >&2
	exit 1
}

output=""
while IFS= read -r -d '' f; do
	# skip binary files
	grep -Iq . "$f" 2>/dev/null || continue
	output+="==> $f <==
$(cat "$f")

"
done < <(find "$DIR" -maxdepth "$DEPTH" -type f -print0 | sort -z)

[ -n "$output" ] || {
	echo "no text files found" >&2
	exit 1
}

printf '%s' "$output" | wl-copy
echo "copied $(printf '%s' "$output" | grep -c '^==> ') files to clipboard"
