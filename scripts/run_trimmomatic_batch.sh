#!/bin/bash

# Batch Trimmomatic script for paired-end trimming

# Author: Samson Olofinsae (2025)

set -e

ADAPTERS="resources/TruSeq3-PE.fa"
THREADS=2
INPUT_DIR="inputs"
OUTPUT_DIR="results/trimmed"
LOG_DIR="results/qc_logs"

mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

echo " Trimmomatic batch started: $(date)"

for SAMPLE in father mother proband; do
    R1="${INPUT_DIR}/${SAMPLE}_R1.fastq.gz"
    R2="${INPUT_DIR}/${SAMPLE}_R2.fastq.gz"

    if [[ -f "$R1" && -f "$R2" ]]; then
        echo " Found: $R1 and $R2"

        LOGFILE="${LOG_DIR}/${SAMPLE}_trimmomatic.log"
        R1_OUT="${OUTPUT_DIR}/${SAMPLE}_R1.trimmed.fastq.gz"
        R1_UNP="${OUTPUT_DIR}/${SAMPLE}_R1.unpaired.fastq.gz"
        R2_OUT="${OUTPUT_DIR}/${SAMPLE}_R2.trimmed.fastq.gz"
        R2_UNP="${OUTPUT_DIR}/${SAMPLE}_R2.unpaired.fastq.gz"

        # Run Trimmomatic with forced quality encoding
        trimmomatic PE -phred33 -threads "$THREADS" "$R1" "$R2" \
            "$R1_OUT" "$R1_UNP" "$R2_OUT" "$R2_UNP" \
            ILLUMINACLIP:"$ADAPTERS":2:30:10 \
            LEADING:3 TRAILING:3 SLIDINGWINDOW:4:20 MINLEN:36 \
            &> "$LOGFILE"

        if [[ $? -eq 0 ]]; then
            echo " Trimmed $SAMPLE"
        else
            echo " Error trimming $SAMPLE – check $LOGFILE"
        fi
    else
        echo "  Skipping $SAMPLE – missing input files"
    fi
done

echo " Trimming batch completed: $(date)"
