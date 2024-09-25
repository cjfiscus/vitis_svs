#!/bin/bash
#SBATCH --job-name=gwas
#SBATCH -o ./std/%j.out
#SBATCH -e ./std/%j.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=cfisc004@ucr.edu
#SBATCH --ntasks=2
#SBATCH --mem=16gb
#SBATCH -t 1-00:00:00
#SBATCH -p gcluster
#SBATCH --array=1-19

# GEMMA 0.98.5

# define variables 
GENO=/gpool/cfiscus/vitis_svs/results/gwas/svs
KINSHIP=/gpool/cfiscus/vitis_svs/results/gwas/related_matrix.cXX.txt
PHENO_NAME=$(head -n "$SLURM_ARRAY_TASK_ID" /gpool/cfiscus/vitis_svs/results/gwas/phenotypes.txt | tail -n 1 | cut -f1)
COL=$(($SLURM_ARRAY_TASK_ID))
OUT=/gpool/cfiscus/vitis_svs/results/gwas

# association with mlm
echo "$PHENO_NAME"
gemma -debug -bfile "$GENO" -n "$COL" -k $KINSHIP -lmm 4 -outdir "$OUT" -o $PHENO_NAME
