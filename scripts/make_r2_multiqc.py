#!/usr/bin/env python3
import csv, argparse
from pathlib import Path

HEADER = """# id: r2_troubleshooter
# section_name: R2 Troubleshooter — pairing & trimming summary
# description: Derived from Trimmomatic run summary (qc_summary.csv). Rows show pairs + drop stats; SKIP/ERROR should be added by log-aware tools if needed.
# plot_type: table
# file_format: tsv
Sample\thas_R1\thas_R2\tinput_pairs\tboth_surviving\tforward_only\treverse_only\tdropped\tremoved_pct\tstatus\tnote
"""

def clean_num(x):
    x = (x or "").strip()
    return x.replace(",", "")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", default="results/qc_summary.csv")
    ap.add_argument("--out", default="results/multiqc_cc/r2_troubleshooter_mqc.tsv")
    ap.add_argument("--run-multiqc", action="store_true")
    ap.add_argument("--multiqc-outdir", default="results/multiqc")
    ap.add_argument("--multiqc-name", default="r2_troubleshooter_multiqc.html")
    args = ap.parse_args()

    in_csv = Path(args.csv)
    out_tsv = Path(args.out)
    out_tsv.parent.mkdir(parents=True, exist_ok=True)

    rows = []
    with in_csv.open(newline="") as fh:
        rd = csv.DictReader(fh)
        # Expected headers: Sample,Input Read Pairs,Both Surviving,Forward Only,Reverse Only,Dropped,Percent Removed
        for r in rd:
            rows.append("\t".join([
                r.get("Sample",""),
                "true","true",
                clean_num(r.get("Input Read Pairs","")),
                clean_num(r.get("Both Surviving","")),
                clean_num(r.get("Forward Only","")),
                clean_num(r.get("Reverse Only","")),
                clean_num(r.get("Dropped","")),
                clean_num(r.get("Percent Removed","")),
                "RUN","ok"
            ]))

    out_tsv.write_text(HEADER + "\n".join(rows) + ("\n" if rows else ""))

    if args.run_multiqc:
        import subprocess, os
        Path(args.multiqc_outdir).mkdir(parents=True, exist_ok=True)
        try:
            subprocess.run(
                ["multiqc", "results", "-o", args.multiqc_outdir, "-n", args.multiqc_name],
                check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
            )
            print(f"MultiQC report: {args.multiqc_outdir}/{args.multiqc_name}")
        except FileNotFoundError:
            print("multiqc not found; install with `pip install multiqc`")
if __name__ == "__main__":
    main()
