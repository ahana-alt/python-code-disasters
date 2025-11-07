#!/usr/bin/env bash
set -euo pipefail

INPUT_DIR=${INPUT_DIR:-/data/python-code-disasters}
OUTPUT_DIR=${OUTPUT_DIR:-/tmp/linecounts-$(date +%s)}
HADOOP_STREAMING_JAR=${HADOOP_STREAMING_JAR:-/usr/lib/hadoop-mapreduce/hadoop-streaming.jar}

hdfs dfs -mkdir -p "$INPUT_DIR"
find . -name "*.py" -maxdepth 3 -print0 | xargs -0 -I{} hdfs dfs -put -f "{}" "$INPUT_DIR/"

hdfs dfs -rm -r -f "$OUTPUT_DIR" || true
hadoop jar "$HADOOP_STREAMING_JAR" \
  -D mapreduce.job.name="linecount-per-file" \
  -mapper mapper.py \
  -reducer reducer.py \
  -files mapper.py,reducer.py \
  -input "$INPUT_DIR" \
  -output "$OUTPUT_DIR"

echo "==== Line counts (per file) ===="
hdfs dfs -cat "$OUTPUT_DIR/part-*"
