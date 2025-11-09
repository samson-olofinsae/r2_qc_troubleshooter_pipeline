#!/usr/bin/env bash
# run_trimmomatic_batch.sh — Paired-end trimming with QC summary (portable/robust)
# Author: Samson Olofinsae (2025)

set -euo pipefail
IFS=$'\n\t'

# ---- Defaults (overridable via env or flags) ----
ADAPTERS="${ADAPTERS:-resources/TruSeq3-PE.fa}"
THREADS="${THREADS:-2}"
INPUT_DIR="${INPUT_DIR:-inputs}"
OUTPUT_DIR="${OUTPUT_DIR:-results/trimmed}"
LOG_DIR="${LOG_DIR:-results/qc_logs}"
SUMMARY_CSV="${SUMMARY_CSV:-results/qc_summary.csv}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [-i INPUT_DIR] [-o OUTPUT_DIR] [-a ADAPTERS] [-t THREADS]
Defaults: INPUT_DIR=$INPUT_DIR, OUTPUT_DIR=$OUTPUT_DIR, ADAPTERS=$ADAPTERS, THREADS=$THREADS
Env overrides supported: ADAPTERS, THREADS, INPUT_DIR, OUTPUT_DIR, LOG_DIR, SUMMARY_CSV
EOF
}

while getopts ":i:o:a:t:h" opt; do
  case "$opt" in
    i) INPUT_DIR="$OPTARG" ;;
    o) OUTPUT_DIR="$OPTARG" ;;
    a) ADAPTERS="$OPTARG" ;;
    t) THREADS="$OPTARG" ;;
    h) usage; exit 0 ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage; exit 2 ;;
  esac
done

# ---- Pre-flight checks ----
command -v trimmomatic >/dev/null 2>&1 || { echo "ERROR: trimmomatic not found in PATH." >&2; exit 127; }
[[ -f "$ADAPTERS" ]] || { echo "ERROR: adapters file not found: $ADAPTERS" >&2; exit 1; }
[[ -d "$INPUT_DIR" ]] || { echo "ERROR: input dir not found: $INPUT_DIR" >&2; exit 1; }

mkdir -p "$OUTPUT_DIR" "$LOG_DIR" "$(dirname "$SUMMARY_CSV")"

echo "Trimmomatic batch started: $(date)"

# CSV header (only if new file)
if [[ ! -s "$SUMMARY_CSV" ]]; then
  echo "Sample,Input Read Pairs,Both Surviving,Forward Only,Reverse Only,Dropped,Percent Removed" > "$SUMMARY_CSV"
fi

# Helper: safe numeric extraction (never fatal)
extract_num() {
  local line="$1" pattern="$2" field="$3"
  local out
  out="$(printf '%s\n' "$line" | grep -oE "$pattern" 2>/dev/null | awk -v f="$field" '{print $f}' 2>/dev/null || true)"
  if [[ -n "$out" ]]; then printf '%s' "$out"; else printf '0'; fi
}

# ---- Sample discovery (R1 pairs) ----
shopt -s nullglob
R1_FILES=("$INPUT_DIR"/*_R1.fastq.gz)
if (( ${#R1_FILES[@]} == 0 )); then
  echo "No *_R1.fastq.gz files found in $INPUT_DIR" >&2
  exit 1
fi

for R1 in "${R1_FILES[@]}"; do
  base="$(basename "$R1")"
  SAMPLE="${base%_R1.fastq.gz}"
  R2="${INPUT_DIR}/${SAMPLE}_R2.fastq.gz"

  if [[ ! -f "$R2" ]]; then
    echo " Skipping ${SAMPLE} — missing mate file: $R2"
    continue
  fi

  echo "Found: $R1 and $R2"

  LOGFILE="${LOG_DIR}/${SAMPLE}_trimmomatic.log"
  R1_OUT="${OUTPUT_DIR}/${SAMPLE}_R1.trimmed.fastq.gz"
  R1_UNP="${OUTPUT_DIR}/${SAMPLE}_R1.unpaired.fastq.gz"
  R2_OUT="${OUTPUT_DIR}/${SAMPLE}_R2.trimmed.fastq.gz"
  R2_UNP="${OUTPUT_DIR}/${SAMPLE}_R2.unpaired.fastq.gz"

  set +e
  trimmomatic PE -phred33 -threads "$THREADS" "$R1" "$R2" \
    "$R1_OUT" "$R1_UNP" "$R2_OUT" "$R2_UNP" \
    ILLUMINACLIP:"$ADAPTERS":2:30:10 \
    LEADING:3 TRAILING:3 SLIDINGWINDOW:4:20 MINLEN:36 \
    &> "$LOGFILE"
  status=$?
  set -e

  if (( status != 0 )); then
    echo " Error trimming ${SAMPLE} – see $LOGFILE"
    continue
  fi

  # Grab the summary line (never fatal if absent)
  STATS_LINE="$(grep -m1 '^Input Read Pairs:' "$LOGFILE" 2>/dev/null || true)"
  if [[ -z "$STATS_LINE" ]]; then
    echo " Warning: no summary line for ${SAMPLE} – check $LOGFILE"
    # Still record a row with zeros so downstream plots don't break
    echo "${SAMPLE},0,0,0,0,0,0.00" >> "$SUMMARY_CSV"
    continue
  fi

  # Temporarily relax pipefail while parsing to avoid aborts on misses
  set +o pipefail

  INPUT="$(extract_num "$STATS_LINE" 'Input Read Pairs: [0-9]+' 4)"
  BOTH="$( extract_num "$STATS_LINE" 'Both Surviving: [0-9]+'   3)"
  FWD="$(  extract_num "$STATS_LINE" 'Forward Only: [0-9]+'     3)"
  REV="$(  extract_num "$STATS_LINE" 'Reverse Only: [0-9]+'     3)"
  DROP="$( extract_num "$STATS_LINE" 'Dropped: [0-9]+'          2)"

  DROP_PCT="$(printf '%s\n' "$STATS_LINE" \
    | grep -oE 'Dropped: [0-9]+ \([0-9.]+%\)' 2>/dev/null \
    | grep -oE '[0-9.]+%' 2>/dev/null \
    | tr -d '%' || true)"
  set -o pipefail

  # Fallback if percent wasn't present
  if [[ -z "$DROP_PCT" ]]; then
    DROP_PCT="$(awk -v d="${DROP:-0}" -v n="${INPUT:-0}" 'BEGIN{ if(n>0){printf "%.2f", (d/n)*100}else{print "0.00"} }')"
  fi

  echo "${SAMPLE}: ${DROP} reads dropped out of ${INPUT} total (${DROP_PCT}%)"

  # Append to CSV
  SAMPLE_CSV="${SAMPLE//,/}"
  echo "${SAMPLE_CSV},${INPUT},${BOTH},${FWD},${REV},${DROP},${DROP_PCT}" >> "$SUMMARY_CSV"
done

echo "Trimming batch completed: $(date)"
