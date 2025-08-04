#!/bin/bash
# download_fasta.sh
# Download the hg19_chr8.fa reference file from Dropbox

set -e

OUTDIR="ref"
FILENAME="hg19_chr8.fa"
URL="https://www.dropbox.com/scl/fi/cl1qe1gsuzrp07tcou8h9/hg19_chr8.fa?rlkey=ibsr8j02zz7vhjf6hf1wdp4ft&st=d8mnf64n&dl=1"

mkdir -p $OUTDIR
echo "📥 Downloading $FILENAME to $OUTDIR/ ..."
curl -L "$URL" -o "$OUTDIR/$FILENAME"

echo " Download complete: $OUTDIR/$FILENAME"
