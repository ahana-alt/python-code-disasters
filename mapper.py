#!/usr/bin/env python3
import os, sys
fname = os.environ.get('mapreduce_map_input_file') or os.environ.get('map_input_file','unknown')
for _ in sys.stdin:
    print(f"{fname}\t1")
