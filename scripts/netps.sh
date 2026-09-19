#!/bin/sh
[ "$1" = watch ] && exec watch -n1 "$0"

printf '%4s %4s  %-9s %-24s %s\n' SOCK EST PROTO PROCESS REMOTE
lsof -i -n -P 2>/dev/null | awk '
NR > 1 {
    k = $1 " " $2
    n[k]++
    if ($10 == "(ESTABLISHED)") est[k]++
    if (!((k, $8) in ps)) { ps[k, $8]; proto[k] = proto[k] $8 "," }
    if (split($9, a, "->") == 2) {
        sub(/:[0-9]+$/, "", a[2])
        if (!((k, a[2]) in rs)) { rs[k, a[2]]; r[k] = r[k] a[2] " " }
    }
}
END {
    for (k in n) printf "%4d %4d  %-9s %-24s %s\n", n[k], est[k] + 0, proto[k], k, r[k]
}' | sort -k1,1rn
