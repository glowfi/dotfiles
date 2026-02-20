#!/usr/bin/env bash

# ============================================================================
# dir2clip - Recursively copy directory tree and file contents to clipboard
# ============================================================================

set -euo pipefail

# ----- Configuration --------------------------------------------------------
IGNORE_DIRS=(".git" "node_modules" "python_env" "__pycache__" ".venv" "venv")
SCRIPT_NAME="$(basename "$0")"

# ----- Functions -------------------------------------------------------------

usage() {
	cat <<EOF
Usage: ${SCRIPT_NAME} <directory>

Recursively traverses a directory (ignoring common junk directories),
builds a file tree + file contents, and copies everything to the clipboard.

Ignored directories: ${IGNORE_DIRS[*]}

Supports: Wayland (wl-copy) and X11 (xclip).
EOF
	exit 1
}

# Detect display server and return the appropriate copy command
get_copy_command() {
	if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
		if command -v wl-copy &>/dev/null; then
			echo "wl-copy"
			return 0
		else
			echo >&2 "Error: Wayland detected but 'wl-copy' not found."
			echo >&2 "Install it:  sudo apt install wl-clipboard  /  sudo pacman -S wl-clipboard"
			exit 1
		fi
	elif [[ -n "${DISPLAY:-}" ]]; then
		if command -v xclip &>/dev/null; then
			echo "xclip -selection clipboard"
			return 0
		elif command -v xsel &>/dev/null; then
			echo "xsel --clipboard --input"
			return 0
		else
			echo >&2 "Error: X11 detected but neither 'xclip' nor 'xsel' found."
			echo >&2 "Install one:  sudo apt install xclip"
			exit 1
		fi
	else
		echo >&2 "Error: No display server detected (neither WAYLAND_DISPLAY nor DISPLAY is set)."
		exit 1
	fi
}

# Build the `tree`-style view, or fall back to `find`
generate_tree() {
	local dir="$1"

	# Build the -I pattern for `tree` (pipe-separated)
	local tree_ignore
	tree_ignore=$(
		IFS='|'
		echo "${IGNORE_DIRS[*]}"
	)

	if command -v tree &>/dev/null; then
		tree -a -I "${tree_ignore}" --charset utf-8 -- "${dir}"
	else
		# Fallback: use find + sed to produce an indented listing
		# Build the -path based prune expression
		local prune_args=()
		for d in "${IGNORE_DIRS[@]}"; do
			prune_args+=(-name "$d" -o)
		done
		# Remove trailing -o
		unset 'prune_args[-1]'

		echo "${dir}"
		(
			cd "${dir}"
			find . \( "${prune_args[@]}" \) -prune -o -print |
				sort |
				tail -n +2 |
				sed 's|[^/]*/|    |g'
		)
	fi
}

# Collect every file path (respecting ignore list)
collect_files() {
	local dir="$1"

	# Build find's prune expression
	local prune_expr=()
	local first=true
	for d in "${IGNORE_DIRS[@]}"; do
		if [[ "${first}" == true ]]; then
			first=false
		else
			prune_expr+=(-o)
		fi
		prune_expr+=(-name "$d")
	done

	find "${dir}" \( "${prune_expr[@]}" \) -prune -o -type f -print | sort
}

# ----- Main ------------------------------------------------------------------

# Argument check
if [[ $# -ne 1 ]]; then
	usage
fi

TARGET_DIR="$1"

if [[ ! -d "${TARGET_DIR}" ]]; then
	echo >&2 "Error: '${TARGET_DIR}' is not a directory."
	exit 1
fi

# Detect clipboard tool early so we fail fast
COPY_CMD=$(get_copy_command)

# ---- Build output -----------------------------------------------------------

OUTPUT=""

# 1) File tree
OUTPUT+="File Tree:"
OUTPUT+=$'\n'"----"$'\n'
OUTPUT+="$(generate_tree "${TARGET_DIR}")"
OUTPUT+=$'\n'"----"$'\n\n'

# 2) File contents
while IFS= read -r filepath; do
	# Relative path for the header
	rel_path="${filepath#"${TARGET_DIR}"/}"

	# Skip binary files (mime check)
	if file --mime-encoding -- "${filepath}" 2>/dev/null | grep -qi 'binary'; then
		OUTPUT+="${rel_path}"$'\n'"----"$'\n'"[binary file skipped]"$'\n'"----"$'\n\n'
		continue
	fi

	OUTPUT+="${rel_path}"
	OUTPUT+=$'\n'"----"$'\n'
	OUTPUT+="$(cat -- "${filepath}")"
	OUTPUT+=$'\n'"----"$'\n\n'

done < <(collect_files "${TARGET_DIR}")

# ---- Copy to clipboard ------------------------------------------------------

# Use eval because COPY_CMD may contain flags (e.g. "xclip -selection clipboard")
echo -n "${OUTPUT}" | eval "${COPY_CMD}"

# ---- Summary ----------------------------------------------------------------
FILE_COUNT=$(collect_files "${TARGET_DIR}" | wc -l)
BYTE_COUNT=$(echo -n "${OUTPUT}" | wc -c)

cat <<EOF
✅  Copied to clipboard!
    Directory : ${TARGET_DIR}
    Files     : ${FILE_COUNT}
    Size      : ${BYTE_COUNT} bytes
    Clipboard : ${COPY_CMD}
EOF
