#!/bin/bash -l

#SBATCH --nodes=1
#SBATCH --ntasks=2
#SBATCH --mem=16G
#SBATCH --output=std/%j.stdout
#SBATCH --error=std/%j.stderr
#SBATCH --mail-user=cfiscus@uci.edu
#SBATCH --mail-type=ALL
#SBATCH --time=7-00:00:00
#SBATCH --job-name="merge"
#SBATCH -p gcluster

## software dependencies
# truvari

# env for smoove
PATH=/gpool/cfiscus/bin/miniconda3/bin:$PATH
source activate truvari

# vars
THREADS=2
DATADIR=/gpool/cfiscus/vitis_svs/data
OUTDIR=/gpool/cfiscus/vitis_svs/results
REF=/gpool/cfiscus/b40-14_v2.0/VITVarB40-14_v2.0.pseudomolecules.hap1.fasta

########## merge across inds
# mk lst of files to merge
ls /gpool/cfiscus/vitis_svs/results/merged/*_merge.vcf.gz > "$DATADIR"/lst2.txt

# merge files 
bcftools merge -m none -l "$DATADIR"/lst2.txt | bgzip > "$OUTDIR"/merged_all.vcf.gz
bcftools index -t "$OUTDIR"/merged_all.vcf.gz

## collapse with truvari
truvari collapse -i "$OUTDIR"/merged_all.vcf.gz -o "$OUTDIR"/svs_all_merged.vcf -c "$OUTDIR"/svs_all_collapsed.vcf -f "$REF" --chain -S 1000000 -k common

## fill tags with bcftools
bcftools index "$OUTDIR"/svs_all_merged.vcf
bcftools +fill-tags "$OUTDIR"/svs_all_merged.vcf -Oz -o "$OUTDIR"/svs_all_merged2.vcf.gz -- -t all
