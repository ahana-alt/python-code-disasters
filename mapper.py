#!/usr/bin/env python3
import sys
import os

filename = os.environ.get('mapreduce_map_input_file', 'unknown')
filename = os.path.basename(filename)

for line in sys.stdin:
    print(f"{filename}\t1")
