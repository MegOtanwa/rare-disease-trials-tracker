#!/bin/bash
# Fetch ALL recruiting clinical trials for rare diseases from ClinicalTrials.gov, page by page

CONDITIONS=("ALS" "myasthenia gravis" "Friedreich ataxia")
TODAY=$(date +%Y-%m-%d)
OUTPUT_DIR="data/raw"
BASE_URL="https://clinicaltrials.gov/api/v2/studies"

mkdir -p "$OUTPUT_DIR"

for CONDITION in "${CONDITIONS[@]}"; do
  QUERY="${CONDITION// /+}"
  FILE_NAME="${CONDITION// /_}"
  OUTPUT_FILE="$OUTPUT_DIR/${FILE_NAME}_${TODAY}.json"
  PAGE=1
  PAGE_TOKEN=""

  echo "Fetching recruiting trials for: $CONDITION"

  while true; do
    URL="${BASE_URL}?query.cond=${QUERY}&filter.overallStatus=RECRUITING&pageSize=100"
    if [ -n "$PAGE_TOKEN" ]; then
      URL="${URL}&pageToken=${PAGE_TOKEN}"
    fi

    PAGE_FILE="$OUTPUT_DIR/${FILE_NAME}_${TODAY}_page${PAGE}.json"
    curl -s "$URL" -o "$PAGE_FILE"
    echo "  Saved page $PAGE"

    PAGE_TOKEN=$(jq -r '.nextPageToken // empty' "$PAGE_FILE")
    if [ -z "$PAGE_TOKEN" ]; then
      break
    fi
    PAGE=$((PAGE + 1))
  done

  jq -s '{studies: map(.studies[])}' "$OUTPUT_DIR/${FILE_NAME}_${TODAY}"_page*.json > "$OUTPUT_FILE"
  rm "$OUTPUT_DIR/${FILE_NAME}_${TODAY}"_page*.json
  echo "Saved $(jq '.studies | length' "$OUTPUT_FILE") trials to $OUTPUT_FILE"
done

echo "Done."