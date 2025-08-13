# R2 QC Troubleshooter Pipeline

A training pipeline designed to simulate real-world quality control (QC) troubleshooting during paired-end FASTQ trimming. This mini-project demonstrates how to debug adapter issues, handle batch processing, and automate reproducible workflows using Bash scripting. It also includes log parsing and a CSV summary report of trimming results.

---

## Project Structure

```
.
├── inputs/                   # Raw FASTQ input files (R1/R2 for samples)
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
- awk (gawk recommended)
- cURL (`curl`)
- Linux/Unix-based operating system
- (Optional) Java 8+ if using `trimmomatic.jar` directly

---

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/samson-olofinsae/r2_qc_troubleshooter_pipeline.git
cd r2_qc_troubleshooter_pipeline
```

### 2. Download the Reference FASTA

> GitHub doesn’t allow files >100MB, so the reference FASTA is not tracked in Git. You must download it manually using:

```bash
bash scripts/download_fasta.sh
```

This will save `hg19_chr8.fa` in the `ref/` folder.

---

## Quick Start

```bash
git clone https://github.com/samson-olofinsae/r2_qc_troubleshooter_pipeline.git
cd r2_qc_troubleshooter_pipeline
bash scripts/download_fasta.sh
bash scripts/run_trimmomatic_batch.sh
```

---

## Run the Pipeline

To batch-trim all FASTQ pairs in `inputs/`, execute:

```bash
bash scripts/run_trimmomatic_batch.sh
```

Each sample will be processed with quality and adapter trimming. Logs and trimmed files will be stored in the `results/` directory.

---

## Output Files

For each sample, the pipeline generates:

- `*.trimmed.fastq.gz` and `*.unpaired.fastq.gz` → `results/trimmed/`
- Trimmomatic log files → `results/qc_logs/`
- Summary CSV → `results/qc_summary.csv`

### Example CSV Summary Output

| Sample  | Input Read Pairs | Both Surviving | Forward Only | Reverse Only | Dropped | Percent Removed |
|---------|------------------|----------------|--------------|--------------|---------|-----------------|
| father  | 2,023,471        | ...            | ...          | ...          | 92,324  | 4.56            |
| mother  | 1,776,099        | ...            | ...          | ...          | 81,888  | 4.61            |
| proband | 2,392,554        | ...            | ...          | ...          | 91,709  | 3.83            |

---

### Column Definitions

- **Sample**: Name of the sample (e.g., father, mother, proband)
- **Input Read Pairs**: Total number of read pairs fed into Trimmomatic
- **Both Surviving**: Read pairs that passed filtering together
- **Forward Only / Reverse Only**: Single reads retained while mate was dropped
- **Dropped**: Read pairs completely discarded
- **Percent Removed**: Proportion of total input reads discarded (%)

---

## Educational Value

This mini-pipeline demonstrates:

- How Trimmomatic behaves with missing or mismatched adapters
- Interpreting QC log outputs effectively
- Writing Bash wrappers with integrated logging and summaries
- Generating clean CSV summaries for downstream QC evaluation
- Designing GitHub-safe pipelines (no large binary files committed)
- Enhancing reproducibility in bioinformatics scripting

It is designed for teaching practical QC debugging and can be reused in workshops or lab onboarding.

---

## Reproducibility

- Scripts are deterministic given the same inputs and adapter file
- All outputs are timestamped and logged per sample
- No large binaries are committed; instructions provided to fetch references

---

## Acknowledgements

This repo is part of a structured training series maintained by [Samson Olofinsae](https://github.com/samson-olofinsae), designed for bioinformatics scientists practicing real-world debugging and pipeline development.

---

## Contact

Have questions or suggestions? Feel free to:
- Open an issue on GitHub
- Connect via [GitHub Profile](https://github.com/samson-olofinsae)
