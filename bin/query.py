#!/usr/bin/env python3
"""
Based on:
https://stackoverflow.com/a/45467190/202168
"""
import os
import re
import select
import sys
import termios
import tty

COLOUR_RE = re.compile(r"rgb:[0-9a-f]{1,4}/[0-9a-f]{1,4}/[0-9a-f]{1,4}")

def query_colours():
    fp = sys.stdin
    fd = fp.fileno()
    if os.isatty(fd):
        old_settings = termios.tcgetattr(fd)
        tty.setraw(fd)
        try:
            print('\033]10;?\07\033]11;?\07')
            r, _, _ = select.select([ fp ], [], [], 0.1)
            if fp in r:
                data = fp.read(48)  # must match length of expected output
                return COLOUR_RE.findall(data)
            else:
                print("no input available")
                return None
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
    else:
        raise ValueError("Not a tty")


if __name__ == "__main__":
    colours = query_colours()
    if colours:
        fg, bg = colours
        print(f"fg={fg}")
        print(f"bg={bg}")
