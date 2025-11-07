#!/usr/bin/env python3
import sys
from itertools import groupby
def key(line): return line.split("\t",1)[0]
for k, group in groupby(sorted(sys.stdin, key=key), key=key):
    s = sum(int(g.split("\t",1)[1]) for g in group)
    print(f'"{k}": {s}')
