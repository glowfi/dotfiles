#!/bin/sh

[ "$1" = watch ] && exec watch -n1 "$0"

printf '%9s %9s  %4s  %s\n' UP DOWN SOCK PROCESS
ss -tinpHO 2>/dev/null | awk '
function human(b,  u, i) {
    split("B K M G T", u, " "); i = 1
    while (b >= 1024 && i < 5) { b /= 1024; i++ }
    return sprintf(i == 1 ? "%d%s" : "%.1f%s", b, u[i])
}
match($0, /users:\(\("[^"]+",pid=[0-9]+/) {
    p = substr($0, RSTART + 9, RLENGTH - 9)     # name",pid=N
    sub(/",pid=/, " ", p)
    n[p]++
    if (match($0, /bytes_sent:[0-9]+/))     tx[p] += substr($0, RSTART + 11, RLENGTH - 11)
    if (match($0, /bytes_received:[0-9]+/)) rx[p] += substr($0, RSTART + 15, RLENGTH - 15)
}
END {
    for (p in n) printf "%12d %9s %9s  %4d  %s\n", tx[p] + rx[p], human(tx[p]), human(rx[p]), n[p], p
}' | sort -k1,1rn | cut -c14-
