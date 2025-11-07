#!/usr/bin/env bash
set -euo pipefail

# expects: PROJECT_ID, REGION, CLUSTER_NAME, BUCKET_NAME, BUILD_ID
: "${PROJECT_ID:?missing} ${REGION:?missing} ${CLUSTER_NAME:?missing} ${BUCKET_NAME:?missing} ${BUILD_ID:?missing}"

# stage job assets + input
gsutil cp mapper.py "gs://${BUCKET_NAME}/jobs/mapper.py"
gsutil cp reducer.py "gs://${BUCKET_NAME}/jobs/reducer.py"

# if you have local sample input folder ./repo-input, upload it:
if [ -d "repo-input" ]; then
  gsutil -m cp -r repo-input "gs://${BUCKET_NAME}/repo-input"
fi

OUT="gs://${BUCKET_NAME}/linecounts-${BUILD_ID}"

# run streaming job
gcloud dataproc jobs submit hadoop \
  --project="${PROJECT_ID}" \
  --region="${REGION}" \
  --cluster="${CLUSTER_NAME}" \
  --jar=file:/usr/lib/hadoop-mapreduce/hadoop-streaming.jar \
  -- \
  -D mapreduce.job.name="linecount-${BUILD_ID}" \
  -files="gs://${BUCKET_NAME}/jobs/mapper.py,gs://${BUCKET_NAME}/jobs/reducer.py" \
  -mapper="python3 mapper.py" \
  -reducer="python3 reducer.py" \
  -input="gs://${BUCKET_NAME}/repo-input" \
  -output="${OUT}"

# show results in logs
gsutil ls "${OUT}/"
gsutil cat "${OUT}/part-*" | head -n 50

