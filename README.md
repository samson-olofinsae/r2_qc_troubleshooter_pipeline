# R2 QC Troubleshooter Pipeline

A training pipeline designed to simulate real-world quality control (QC) troubleshooting during paired-end FASTQ trimming.  
It demonstrates how to debug adapter issues, handle batch processing, and automate reproducible workflows using Bash scripting.  
The pipeline includes log parsing and a CSV summary report of trimming results.

---

## Project Structure

```
.
├── inputs/                   # Raw FASTQ input files (R1/R2 for samples) - user provided
├── ref/                      # Reference FASTA file (downloaded separately)
├── resources/                # Adapter file (TruSeq3-PE.fa)
├── results/
│   ├── trimmed/              # Output: Trimmed and unpaired FASTQ files
│   ├── qc_logs/              # Output: Trimmomatic logs for each sample
│   └── qc_summary.csv        # Output: Tabular summary of trimming stats
├── scripts/
│   ├── run_trimmomatic_batch.sh   # Main trimming + log summariser script
│   └── download_fasta.sh          # Fetches hg19_chr8.fa from Dropbox
└── .gitignore
```

---

## Requirements

- [Trimmomatic](http://www.usadellab.org/cms/?page=trimmomatic) ≥ 0.39  
- Bash ≥ 4.0  
- `awk` (gawk recommended)  
- `curl`  
- Linux/Unix-based operating system  
- *(Optional)* Java 8+ if using `trimmomatic.jar` directly  

---

## Setup

### 1. Clone the Repository

```bash
git clone https://github.com/samson-olofinsae/r2_qc_troubleshooter_pipeline.git
cd r2_qc_troubleshooter_pipeline
```

### 2. Download the Reference FASTA

> GitHub doesn’t allow files >100MB, so the reference FASTA is not tracked.  
> Download it manually using:

```bash
bash scripts/download_fasta.sh
```

This saves `hg19_chr8.fa` in the `ref/` folder.

---

## Quick Start

```bash
git clone https://github.com/samson-olofinsae/r2_qc_troubleshooter_pipeline.git
cd r2_qc_troubleshooter_pipeline
bash scripts/download_fasta.sh
bash scripts/run_trimmomatic_batch.sh
```

---

## Running the Pipeline

To batch-trim all FASTQ pairs in `inputs/`:

```bash
bash scripts/run_trimmomatic_batch.sh
```

Logs and trimmed files will be stored in the `results/` directory.

---

## Output Files

For each sample, the pipeline generates:

- `*.trimmed.fastq.gz` and `*.unpaired.fastq.gz` → `results/trimmed/`
- Trimmomatic log files → `results/qc_logs/`
- Summary CSV → `results/qc_summary.csv`

---

### Example CSV Summary Output

| Sample  | Input Read Pairs | Both Surviving | Forward Only | Reverse Only | Dropped | Percent Removed |
|---------|------------------|----------------|--------------|--------------|---------|-----------------|
| sampleA | 2,023,471        | ...            | ...          | ...          | 92,324  | 4.56            |
| sampleB | 1,776,099        | ...            | ...          | ...          | 81,888  | 4.61            |
| sampleC | 2,392,554        | ...            | ...          | ...          | 91,709  | 3.83            |

---

### Column Definitions

- **Sample** — Name of the sample (e.g., tumour, normal, proband)  
- **Input Read Pairs** — Total number of read pairs fed into Trimmomatic  
- **Both Surviving** — Read pairs retained together after filtering  
- **Forward Only / Reverse Only** — Single reads retained while mate was dropped  
- **Dropped** — Read pairs completely discarded  
- **Percent Removed** — Proportion of total input reads discarded (%)  

---

## Demo 1 — Fault Tolerance (Continue-on-Failure)

Simulates a file permission error so one failing sample doesn’t stop the batch.

```bash
# Replace <sample> with your sample basename (without _R1/_R2)
# Example: tumour for tumour_R1.fastq.gz and tumour_R2.fastq.gz

# 1. Back up the R2 file
cp "inputs/<sample>_R2.fastq.gz" "inputs/<sample>_R2.fastq.gz.bak"

# 2. Remove permissions to cause a 'Permission denied' error
chmod 000 "inputs/<sample>_R2.fastq.gz"

# 3. Run the batch script
bash scripts/run_trimmomatic_batch.sh

# 4. Confirm <sample> is skipped in the CSV
grep -n "^<sample>," results/qc_summary.csv || echo "<sample> skipped (as expected)"

# 5. Restore file
chmod 644 "inputs/<sample>_R2.fastq.gz"
mv -f "inputs/<sample>_R2.fastq.gz.bak" "inputs/<sample>_R2.fastq.gz"
```

---

## Demo 2 — Missing Sample Mate (Skip on Missing Pair)

Simulates a missing `_R2` mate file.

```bash
# Replace <sample> with your sample basename (without _R1/_R2)

# 1. Rename R2 file to simulate missing mate
mv "inputs/<sample>_R2.fastq.gz" "inputs/<sample>_R2.fastq.gz.bak"

# 2. Run the batch script
bash scripts/run_trimmomatic_batch.sh

# 3. Confirm <sample> is skipped
grep -n "^<sample>," results/qc_summary.csv || echo "<sample> skipped due to missing R2 (as expected)"

# 4. Restore original R2 file
mv "inputs/<sample>_R2.fastq.gz.bak" "inputs/<sample>_R2.fastq.gz"
```

**Expected Outcome**  
- `<sample>` is skipped with a warning in `results/qc_logs/`.  
- Other samples process normally.  
- `<sample>` does not appear in `results/qc_summary.csv`.  

**Finding Your `<sample>` Names**  
List all detected sample basenames:  
```bash
ls inputs/*_R1.fastq.gz 2>/dev/null | xargs -n1 basename | sed 's/_R1\.fastq\.gz$//'
```

---

## Educational Value

This pipeline demonstrates:

- How Trimmomatic behaves with missing or mismatched adapters  
- How to interpret QC log outputs effectively  
- Writing Bash wrappers with integrated logging and summaries  
- Generating clean CSV summaries for downstream QC evaluation  
- Designing GitHub-safe pipelines (no large binary files committed)  
- Enhancing reproducibility in bioinformatics scripting  

---

## Reproducibility

- Scripts are deterministic given the same inputs and adapter file  
- Outputs are timestamped and logged per sample  
- No large binaries are committed; references are fetched via scripts  

---

## Acknowledgements

Maintained by [Samson Olofinsae](https://github.com/samson-olofinsae) as part of a structured bioinformatics training series.  
Designed for scientists practicing real-world debugging and pipeline development.

---

## Contact

Questions or suggestions?  
- Open an issue on GitHub  
- Connect via [GitHub Profile](https://github.com/samson-olofinsae)  
