#!/usr/bin/env python3
import sys

current_file = None
count = 0

for line in sys.stdin:
    filename, val = line.strip().split('\t')
    val = int(val)
    
    if filename == current_file:
        count += val
    else:
        if current_file:
            print(f'"{current_file}": {count}')
        current_file = filename
        count = val

if current_file:
    print(f'"{current_file}": {count}')
