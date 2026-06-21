#!/bin/bash
HOSTS="termux
some100
wghwang-p14s
office
oci.stania.pe.kr"

if [ -z "$1" ]; then
    echo "$HOSTS"
elif [ "$1" = "termux" ]; then
    setsid wezterm start -- bash -l >/dev/null 2>&1 &
    disown
else
    setsid wezterm start -- mosh "$1" >/dev/null 2>&1 &
    disown
fi
