# R2 QC Troubleshooter Pipeline

A lightweight **training pipeline** to practice *real-world QC troubleshooting* during paired‑end FASTQ trimming.  
It demonstrates how to debug adapter issues, batch‑process samples, and automate reproducible workflows using Bash scripting.

**Key features**
- Batch trimming of paired FASTQs with **Trimmomatic**
- Automated **log parsing → CSV** summary of results
- Built‑in **fault‑tolerance demos** (permission error, missing mate)
- Reproducible, dependency‑light, and GitHub‑safe (no large binaries tracked)

---

## Project Structure

```
.
├── inputs/           # User-provided FASTQ files (_R1/_R2)
├── ref/              # Reference FASTA (downloaded separately)
├── resources/        # Adapter file (TruSeq3-PE.fa)
├── results/
│   ├── trimmed/      # Trimmed and unpaired FASTQs
│   ├── qc_logs/      # Trimmomatic logs
│   └── qc_summary.csv
├── scripts/
│   ├── run_trimmomatic_batch.sh   # Main batch + log summariser
│   └── download_fasta.sh          # Fetches hg19_chr8.fa
└── .gitignore
```

---

## Requirements

- [Trimmomatic](http://www.usadellab.org/cms/?page=trimmomatic) ≥ 0.39  
- Bash ≥ 4.0, `awk`, `curl`  
- Linux/Unix-based OS  
- *(Optional)* Java 8+ if using `trimmomatic.jar` directly

> **Adapters**: default adapter file is `resources/TruSeq3-PE.fa` (Illumina TruSeq). Replace or edit to suit your library prep.

---

## Setup

### 1) Clone the repository

```bash
git clone https://github.com/samson-olofinsae/r2_qc_troubleshooter_pipeline.git
cd r2_qc_troubleshooter_pipeline
```

### 2) Download the reference FASTA
GitHub does not track files >100 MB. Fetch the small demo FASTA used in examples:

```bash
bash scripts/download_fasta.sh
```
This saves `hg19_chr8.fa` under `ref/`.

> The pipeline does **not** require the FASTA to run trimming, but it is included to mirror real projects where reference files exist alongside reads.

---

## Input expectations

- Files must follow the pattern: `inputs/<sample>_R1.fastq.gz` and `inputs/<sample>_R2.fastq.gz`.
- Samples are discovered by scanning for `_R1.fastq.gz` and pairing with the corresponding `_R2.fastq.gz`.

List detected sample basenames:
```bash
ls inputs/*_R1.fastq.gz 2>/dev/null | xargs -n1 basename | sed 's/_R1\.fastq\.gz$//'
```

---

## Quick Start

```bash
# from the repo root
bash scripts/download_fasta.sh        # optional helper
bash scripts/run_trimmomatic_batch.sh # trims all pairs in inputs/
```

**Outputs** (under `results/`):
- Trimmed FASTQs → `results/trimmed/`
- Trimmomatic logs → `results/qc_logs/`
- CSV summary → `results/qc_summary.csv`

---

## Example CSV Summary

| Sample  | Input Pairs | Both Surviving | Forward Only | Reverse Only | Dropped | % Removed |
|---------|-------------|----------------|--------------|--------------|---------|-----------|
| sampleA | 2,023,471   | …              | …            | …            | 92,324  | 4.56      |
| sampleB | 1,776,099   | …              | …            | …            | 81,888  | 4.61      |
| sampleC | 2,392,554   | …              | …            | …            | 91,709  | 3.83      |

**Column definitions**
- **Sample** — Name of the sample (e.g., tumour, normal, proband)  
- **Input Read Pairs** — Total number of read pairs fed into Trimmomatic 
- **Both Surviving** — paired reads retained  
- **Forward/Reverse Only** — orphan reads retained when the mate was dropped  
- **Dropped** — read pairs discarded  
- **% Removed** — proportion of input pairs discarded

---

## Educational Demos
- **Demo 1 – Fault Tolerance**: shows how a failing sample (e.g. permission error) is skipped gracefully.  
- **Demo 2 – Missing Mate**: simulates absent `_R2` file → sample skipped, others continue.  

These demos illustrate *real debugging scenarios* analysts face in production pipelines.  

## Demo 1 — Fault Tolerance (Continue‑on‑Failure)

Simulates a file permission error so **one failing sample** doesn’t stop the batch.

```bash
# Replace <sample> with your sample basename (without _R1/_R2)
# Example: tumour for tumour_R1.fastq.gz and tumour_R2.fastq.gz

# 1) Back up the R2 file
cp "inputs/<sample>_R2.fastq.gz" "inputs/<sample>_R2.fastq.gz.bak"

# 2) Remove permissions to cause a 'Permission denied' error
chmod 000 "inputs/<sample>_R2.fastq.gz"

# 3) Run the batch script
bash scripts/run_trimmomatic_batch.sh

# 4) Confirm <sample> is skipped in the CSV
grep -n "^<sample>," results/qc_summary.csv || echo "<sample> skipped (as expected)"

# 5) Restore file
chmod 644 "inputs/<sample>_R2.fastq.gz"
mv -f "inputs/<sample>_R2.fastq.gz.bak" "inputs/<sample>_R2.fastq.gz"
```

**Expected outcome**
- `<sample>` is skipped with a warning in `results/qc_logs/`.
- Other samples process normally.
- `<sample>` does **not** appear in `results/qc_summary.csv`.

---

## Demo 2 — Missing Sample Mate (Skip on Missing Pair)

Simulates a missing `_R2` mate file.

```bash
# Replace <sample> with your sample basename (without _R1/_R2)

# 1) Rename R2 file to simulate missing mate
mv "inputs/<sample>_R2.fastq.gz" "inputs/<sample>_R2.fastq.gz.bak"

# 2) Run the batch script
bash scripts/run_trimmomatic_batch.sh

# 3) Confirm <sample> is skipped
grep -n "^<sample>," results/qc_summary.csv || echo "<sample> skipped due to missing R2 (as expected)"

# 4) Restore original R2 file
mv "inputs/<sample>_R2.fastq.gz.bak" "inputs/<sample>_R2.fastq.gz"
```

**Expected outcome**
- `<sample>` is skipped with a warning in `results/qc_logs/`.
- Other samples process normally.
- `<sample>` does **not** appear in `results/qc_summary.csv`.

---

## Educational value

This pipeline helps you practice:
- How **Trimmomatic** behaves under common error cases
- Reading and **interpreting QC logs**
- Writing **Bash wrappers** with error handling + summarisation
- Generating **clean CSV** outputs for downstream QC evaluation
- Designing **fail‑safe** automation that *continues* past bad samples

---

## Reproducibility

- Deterministic outputs given the same inputs and adapter file
- External resources fetched via script (no large binaries committed)
- Logs and CSVs standardised for comparison across runs

---

## Tips & troubleshooting

- **Adapter file**: ensure the adapters in `resources/TruSeq3-PE.fa` match your library; otherwise expect elevated clipping/dropping.
- **File names**: mismatched basenames (e.g., `_R1` without `_R2`) will be **skipped** by design.
- **Permissions**: if you test Demo 1 and forget to restore permissions, the sample will keep being skipped.
- **Disk space**: trimming produces multiple FASTQs; ensure `results/trimmed/` has sufficient space.

---

## Citation

If you use or adapt this pipeline in training or teaching, please cite:  
**Samson Olofinsae. R2 QC Troubleshooter Pipeline. GitHub 2025.**  
<https://github.com/samson-olofinsae/r2_qc_troubleshooter_pipeline>

---

## Contact

Questions or suggestions?
- Open an **issue** on GitHub (preferred)
- Connect via **[GitHub Profile](https://github.com/samson-olofinsae)**
