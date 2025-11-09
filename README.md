# R2 QC Troubleshooter Pipeline

A lightweight **training pipeline** to practice *real-world QC troubleshooting* during paired-end FASTQ trimming.  
It demonstrates how to debug adapter issues, batch-process samples, and automate reproducible workflows using Bash scripting.

**Key features**
- Batch trimming of paired FASTQs with **Trimmomatic**
- Automated **log parsing → CSV** summary of results
- Built-in **fault-tolerance demos** (permission error, missing mate)
- **NEW:** **MultiQC integration** via a **standalone report builder** (`scripts/make_r2_multiqc.py`) that converts the CSV into a MultiQC custom-content table and (optionally) builds an HTML report
- Reproducible, dependency-light, and GitHub-safe (no large binaries tracked)

---

## Project Structure

```
.
├── inputs/                 # User-provided FASTQ files (_R1/_R2)
├── ref/                    # Reference FASTA (downloaded separately)
├── resources/              # Adapter file (TruSeq3-PE.fa)
├── results/
│   ├── trimmed/            # Trimmed and unpaired FASTQs
│   ├── qc_logs/            # Trimmomatic logs
│   ├── qc_summary.csv      # Per-sample trimming summary (from the batch script)
│   ├── multiqc_cc/         # *_mqc.tsv custom-content tables (generated)
│   └── multiqc/            # MultiQC HTML reports (generated)
├── scripts/
│   ├── run_trimmomatic_batch.sh   # Main batch + log summariser
│   ├── make_r2_multiqc.py         # NEW: CSV → MultiQC custom table (+ optional HTML)
│   └── download_fasta.sh          # Fetches hg19_chr8.fa
└── .gitignore
```

---

## Requirements

- [Trimmomatic](http://www.usadellab.org/cms/?page=trimmomatic) ≥ 0.39
- Bash ≥ 4.0, `awk`, `curl`
- Linux/Unix-based OS
- *(Optional)* Java 8+ if using `trimmomatic.jar` directly
- *(Optional)* **MultiQC** for HTML reports → `pip install multiqc` (or `mamba/conda install -c bioconda multiqc`)

> **Adapters**: default adapter file is `resources/TruSeq3-PE.fa` (Illumina TruSeq). Replace or edit to suit your library prep.

---

## Setup

### 1) Clone the repository

```bash
git clone https://github.com/samson-olofinsae/r2_qc_troubleshooter_pipeline.git
cd r2_qc_troubleshooter_pipeline
```

### 2) Download the reference FASTA (optional helper)

```bash
bash scripts/download_fasta.sh
```

> The pipeline does **not** require the FASTA to run trimming, but it mirrors real projects where reference files exist alongside reads.

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
bash scripts/run_trimmomatic_batch.sh   # trims all pairs in inputs/
```

**Outputs** (under `results/`):
- Trimmed FASTQs -> `results/trimmed/`
- Trimmomatic logs -> `results/qc_logs/`
- CSV summary -> `results/qc_summary.csv`

---

# Optional: Run on Your Own FASTQs

By default, this repository ships with small **demo FASTQ pairs** inside `inputs/` - ideal for training and reproducing the examples shown above.

If you want to test the pipeline on your own sequencing data, simply replace or copy your files into the `inputs/` directory using this naming convention:

```
inputs/<sample_name>_R1.fastq.gz
inputs/<sample_name>_R2.fastq.gz
```

Then re-run:

```bash
bash scripts/run_trimmomatic_batch.sh
```

### Notes

- You can include multiple samples; the script automatically pairs `_R1` and `_R2` files by their basename.
- Use the `-a` flag to point to a different adapter file if your library prep differs:
  ```bash
  bash scripts/run_trimmomatic_batch.sh -a /path/to/your_adapters.fa
  ```
- Increase threads for larger datasets:
  ```bash
  bash scripts/run_trimmomatic_batch.sh -t 8
  ```
- Outputs (`results/trimmed/`, `results/qc_logs/`, etc.) are created automatically.
- For a clean slate before each run, use the optional **fresh mode**:
  ```bash
  bash scripts/run_trimmomatic_batch.sh -f
  ```

> **Important:** This project is designed for **training and educational purposes**.  
> It is **not validated for diagnostic or clinical workflows**.  
> Always verify real data using production-grade pipelines.


## NEW: MultiQC report (Option B: standalone builder)

We keep the pipeline clean and generate reports **afterward** using a small helper.

### Build/refresh the MultiQC table + HTML
```bash
# CSV -> MultiQC custom table (+ optional HTML)
python scripts/make_r2_multiqc.py --csv results/qc_summary.csv --out results/multiqc_cc/r2_troubleshooter_mqc.tsv --run-multiqc --multiqc-outdir results/multiqc --multiqc-name r2_troubleshooter_multiqc.html
```

- The command writes a custom-content TSV here:
  - `results/multiqc_cc/r2_troubleshooter_mqc.tsv`
- If `multiqc` is installed, it also creates:
  - `results/multiqc/r2_troubleshooter_multiqc.html`

Rebuild safely (overwrite HTML):
```bash
multiqc results -o results/multiqc -n r2_troubleshooter_multiqc.html -f
```

### What the MultiQC table shows (per sample)
Columns in **R2 Troubleshooter - pairing & trimming summary**:

- **has_R1 / has_R2** - whether both mates were found (expected: `true/true`; a missing mate would be flagged `SKIP`)
- **input_pairs** - total read pairs given to Trimmomatic
- **both_surviving** - pairs kept after trimming
- **forward_only / reverse_only** - orphan reads retained when the mate was dropped
- **dropped** - read pairs discarded
- **removed_pct** - `(dropped / input_pairs) × 100`
- **status / note** - run outcome summary (`RUN/ok`; you’ll see `SKIP` or `ERROR` if you choose to add log-aware rows later)

> Tip: MultiQC’s **General Statistics** (top panel) is numeric-only. Text fields (`status`, `note`) won’t display there; they are visible in this custom section.

---

## Example CSV Summary

| Sample  | Input Pairs | Both Surviving | Forward Only | Reverse Only | Dropped | % Removed |
|---------|-------------|----------------|--------------|--------------|---------|-----------|
| sampleA | 2,023,471   | …              | …            | …            | 92,324  | 4.56      |
| sampleB | 1,776,099   | …              | …            | …            | 81,888  | 4.61      |
| sampleC | 2,392,554   | …              | …            | …            | 91,709  | 3.83      |

**Column definitions**
- **Sample** - sample name (e.g., tumour, normal, proband)
- **Input Read Pairs** - total read pairs fed into Trimmomatic
- **Both Surviving** - paired reads retained
- **Forward/Reverse Only** - orphan reads retained when the mate was dropped
- **Dropped** - read pairs discarded
- **% Removed** - proportion of input pairs discarded

---

## Educational Demos

These demos illustrate *real debugging scenarios* analysts face in production pipelines.

### Demo 1 - Fault Tolerance (Continue‑on‑Failure)

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

### Demo 2 - Missing Sample Mate (Skip on Missing Pair)

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
- Reading and **interpreting QC logs/metrics**
- Writing **Bash wrappers** with error handling + summarisation
- Generating **clean CSV** outputs and **MultiQC** reports for at-a-glance review
- Designing **fail‑safe** automation that *continues* past bad samples

---

## Reproducibility

- Deterministic outputs given the same inputs and adapter file
- External resources fetched via script (no large binaries committed)
- Logs, CSVs, and reports standardised for comparison across runs

---

## Tips & troubleshooting

- **Adapter file**: ensure the adapters in `resources/TruSeq3-PE.fa` match your library; otherwise expect elevated clipping/dropping.
- **File names**: mismatched basenames (e.g., `_R1` without `_R2`) will be **skipped** by design.
- **General Statistics vs Section**: if a value doesn’t appear in General Stats, scroll to the **R2 Troubleshooter** section (text fields live there).
- **Force rebuild**: pass `-f` to `multiqc` to overwrite an existing HTML (`… -f`).
- **Tabs**: MultiQC TSVs must be **tab-separated**; “wobbly” spacing in a text editor is normal and won’t affect parsing.

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
