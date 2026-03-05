#!/bin/bash

# https://lwn.net/Articles/665163/

# see https://github.com/egberts/shell-term-background/blob/master/term-background.bash
# for some more advanced heuristics

# takes a single arg:
# 10 = fg color
# 11 = bg color

settings=$(stty -g)
stty -echo -icanon -echoctl
echo -ne "\033]$1;?\007"
# WARNING: this will hang if can't read 24 bytes:
resp=$(dd bs=1 count=24 2>/dev/null)
resp=$(echo -n "$resp" | od -c -An -j5 -N18)
echo "${resp//[[:space:]]/}"
stty "$settings"

# parse echoed output to extract rgb colour
#
# example output:
# rgb:f54f/f54f/f54f
#
# values are 48-bit hex colour (!)

# https://www.x.org/releases/X11R7.7/doc/libX11/libX11/libX11.html#RGB_Device_String_Specification
# it seems that, as with CSS hex, abbreviated c is treated as cccc ("scaled in 16 bits")
