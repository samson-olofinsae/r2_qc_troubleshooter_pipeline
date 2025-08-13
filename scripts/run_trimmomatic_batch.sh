#!/usr/bin/env bash
# run_trimmomatic_batch.sh — Paired-end trimming with QC summary (polished)
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

  echo " Found: $R1 and $R2"

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

  # Parse the summary line
  STATS_LINE="$(grep -m1 '^Input Read Pairs:' "$LOGFILE" || true)"
  if [[ -z "$STATS_LINE" ]]; then
    echo " Warning: no summary line for ${SAMPLE} – check $LOGFILE"
    continue
  fi

  # Typical format:
  # Input Read Pairs: 2023471 Both Surviving: 193... (95.44%) Forward Only: ... Reverse Only: ... Dropped: 92324 (4.56%)
  INPUT="$(awk '{print $4}' <<<"$STATS_LINE")"
  BOTH="$(awk '{for(i=1;i<=NF;i++) if($i=="Both") print $(i+2)}' <<<"$STATS_LINE" | tr -d '()%')"
  FWD="$(awk '{for(i=1;i<=NF;i++) if($i=="Forward") print $(i+3)}' <<<"$STATS_LINE" | tr -d '()%')"
  REV="$(awk '{for(i=1;i<=NF;i++) if($i=="Reverse") print $(i+3)}' <<<"$STATS_LINE" | tr -d '()%')"
  DROP="$(awk '{for(i=1;i<=NF;i++) if($i=="Dropped:") print $(i+1)}' <<<"$STATS_LINE" | tr -d ',')"

  # Compute percent removed from counts if percent missing
  if DROP_PCT_RAW="$(awk '{for(i=1;i<=NF;i++) if($i=="Dropped:") print $(i+2)}' <<<"$STATS_LINE")"; then
    DROP_PCT="$(tr -d '()%,' <<<"$DROP_PCT_RAW" || true)"
  fi
  if [[ -z "${DROP_PCT:-}" ]]; then
    DROP_PCT="$(awk -v d="$DROP" -v n="$INPUT" 'BEGIN{ if(n>0){printf "%.2f", (d/n)*100}else{print "0.00"} }')"
  fi

  echo "  ${SAMPLE}: ${DROP} reads dropped out of ${INPUT} total (${DROP_PCT}%)"

  # Append to CSV
  printf '%q,%s,%s,%s,%s,%s,%.2f\n' \
    "$SAMPLE" "$INPUT" "$BOTH" "$FWD" "$REV" "$DROP" "$DROP_PCT" | sed 's/\\//g' >> "$SUMMARY_CSV"
done

echo "Trimming batch completed: $(date)"
