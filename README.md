# R2 QC Troubleshooter Pipeline

A training pipeline designed to simulate real-world quality control (QC) troubleshooting during paired-end FASTQ trimming. This mini-project demonstrates how to debug adapter issues, handle batch processing, and automate reproducible workflows using bash scripting.

---

##  Project Structure

```
.
├── inputs/                   # Raw FASTQ input files (R1/R2 for 3 samples)
├── ref/                     # Reference FASTA file (downloaded separately)
├── resources/               # Adapter file (TruSeq3-PE.fa)
├── results/
│   ├── trimmed/             # Output: Trimmed and unpaired FASTQ files
│   └── qc_logs/             # Output: Trimmomatic logs for each sample
├── scripts/
│   ├── run_trimmomatic_batch.sh   # Main trimming script
│   └── download_fasta.sh          # Fetches hg19_chr8.fa from Dropbox
└── .gitignore
```

---

##  Requirements

- [Trimmomatic](http://www.usadellab.org/cms/?page=trimmomatic)
- Bash shell (`bash`)
- cURL (`curl`)
- Linux/Unix-based operating system

---

##  Setup Instructions

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

##  Run the Pipeline

To batch-trim all FASTQ pairs (Father, Mother, Proband), execute:

```bash
bash scripts/run_trimmomatic_batch.sh
```

Each sample will be processed with quality and adapter trimming. Logs and trimmed files will be stored in the `results/` directory.

---

##  Output & Logs

Each sample produces:
- `*.trimmed.fastq.gz` and `*.unpaired.fastq.gz` files in `results/trimmed/`
- A detailed log file in `results/qc_logs/`

Each log includes:
- Quality encoding detected
- Adapter matching behavior
- Read survival statistics (e.g., Both Surviving %, Dropped %, etc.)

---

##  Key Learning Outcomes

By using this training repo, you’ll gain hands-on understanding of:
- How Trimmomatic behaves when adapter files are missing or partial
- How to spot misleading 'success' messages without full trimming
- Log-based validation of QC outcomes
- GitHub-safe pipeline design (i.e., excluding large files)
- Script automation and reproducibility in bioinformatics

---

##  Acknowledgements

This repo is part of a structured training series maintained by [Samson Olofinsae](https://github.com/samson-olofinsae), designed for bioinformatics scientists practicing real-world debugging in pipeline development.

---

##  Contact

Have questions or suggestions? Feel free to:
- Open an issue on GitHub
- Connect via [GitHub Profile](https://github.com/samson-olofinsae)