#!/bin/bash
#SBATCH --job-name=calc_mtx
#SBATCH -o %j.out
#SBATCH -e %j.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=cfiscus@uci.edu
#SBATCH --ntasks=2
#SBATCH --mem=64gb
#SBATCH -t 1-00:00:00
#SBATCH -p gcluster

# GEMMA 0.98.4

# define vars
GENO=/gpool/cfiscus/vitis_svs/results/gwas/svs
OUT=/gpool/cfiscus/vitis_svs/results/gwas

# calculate centered relatedness matrix
gemma -bfile "$GENO" -gk 1 -outdir "$OUT" -o related_matrix
