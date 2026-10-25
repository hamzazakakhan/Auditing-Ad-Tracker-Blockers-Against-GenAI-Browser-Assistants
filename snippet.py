#!/usr/bin/env python3
"""Print context windows around regex matches in (possibly minified single-line) JS.

Usage: python3 -I snippet.py <file> <regex> [max_matches=3] [before=80] [after=240]
Prints each match with surrounding characters so minified one-liners are readable.
Read-only; does not import anything from the target's directory.
"""
import re
import sys


def main() -> None:
    path, pat = sys.argv[1], sys.argv[2]
    n = int(sys.argv[3]) if len(sys.argv) > 3 else 3
    before = int(sys.argv[4]) if len(sys.argv) > 4 else 80
    after = int(sys.argv[5]) if len(sys.argv) > 5 else 240
    data = open(path, "r", errors="replace").read()
    rx = re.compile(pat)
    count = 0
    for m in rx.finditer(data):
        s = max(0, m.start() - before)
        e = min(len(data), m.end() + after)
        print(f"\n--- match {count+1} @ offset {m.start()} ---")
        print(data[s:e].replace("\n", " "))
        count += 1
        if count >= n:
            break
    print(f"\n[{count} match(es) shown of pattern {pat!r} in {path}]")


if __name__ == "__main__":
    main()
