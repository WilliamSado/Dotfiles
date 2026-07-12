#!/bin/sh

path="$1"
delay="${2:-0.5}"
log="/tmp/quickshell-capture.log"

: > "$log"
sleep "$delay"

mkdir -p "$(dirname "$path")" 2>>"$log" || exit 1

area="$(slurp 2>>"$log")" || exit 2
[ -n "$area" ] || exit 3

grim -g "$area" "$path" 2>>"$log" || exit 4
test -s "$path" || exit 5

wl-copy --type image/png < "$path" 2>>"$log" || exit 6
