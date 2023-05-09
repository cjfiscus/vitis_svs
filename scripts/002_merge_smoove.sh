#!/bin/bash -l

#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --mem=32G
#SBATCH --output=%j.stdout
#SBATCH --error=%j.stderr
#SBATCH --mail-user=cfiscus@uci.edu
#SBATCH --mail-type=ALL
#SBATCH --time=7-00:00:00
#SBATCH --job-name="sv"
#SBATCH -p gcluster

## software dependencies
### smoove 0.2.8 wrapping lumpy 0.2.13

# env for smoove
PATH=/gpool/cfiscus/bin/miniconda3/bin:$PATH
source activate sv_calling

# initialize temp dir

# vars
THREADS=8
LST=/gpool/cfiscus/vitis_svs/data/sample_table.txt
OUTDIR=/gpool/cfiscus/vitis_svs/results
REF=/gpool/cfiscus/b40-14_v2.0/VITVarB40-14_v2.0.pseudomolecules.hap1.fasta

smoove merge --name smoove_merged -f "$REF" --outdir "$OUTDIR" "$OUTDIR"/lumpy/*.genotyped.vcf.gz
