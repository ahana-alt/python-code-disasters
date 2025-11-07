#!/usr/bin/env bash
set -euo pipefail

REGION="${REGION:?missing}"
CLUSTER_NAME="${CLUSTER_NAME:?missing}"
BUCKET_NAME="${BUCKET_NAME:?missing}"
BUCKET_URI="gs://${BUCKET_NAME}"

# Stage repo content as input
gsutil ls "${BUCKET_URI}" >/dev/null 2>&1 || gsutil mb -l "${REGION}" "${BUCKET_URI}"
gsutil -m rsync -r -x '(^|/)\.' . "${BUCKET_URI}/repo-input"

# Submit Hadoop Streaming job
OUT_PATH="${BUCKET_URI}/linecounts-${BUILD_ID:-$(date +%s)}"
gcloud dataproc jobs submit hadoop \
  --region="${REGION}" \
  --cluster="${CLUSTER_NAME}" \
  --jar=file:/usr/lib/hadoop-mapreduce/hadoop-streaming.jar \
  --files=mapper.py,reducer.py \
  -- \
  -D mapreduce.job.name=linecount-per-file \
  -mapper mapper.py \
  -reducer reducer.py \
  -input "${BUCKET_URI}/repo-input" \
  -output "${OUT_PATH}"

echo "==== OUTPUT (${OUT_PATH}) ====" | tee dataproc-output.txt
gsutil cat "${OUT_PATH}/part-*" | tee -a dataproc-output.txt

