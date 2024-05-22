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
#SBATCH --array=1-182

## software dependencies
# array will be 1-173 

# env for smoove
PATH=/gpool/cfiscus/bin/miniconda3/bin:$PATH
source activate truvari

# vars
THREADS=2
DATADIR=/gpool/cfiscus/vitis_svs/data
OUTDIR=/gpool/cfiscus/vitis_svs/results/merged
REF=/gpool/cfiscus/b40-14_v2.0/VITVarB40-14_v2.0.pseudomolecules.hap1.fasta
TEMP_DIR=/gpool/cfiscus/temp
LST="$DATADIR"/lst.txt
SAMP=$(head -n "$SLURM_ARRAY_TASK_ID" "$LST" | tail -n 1)

TEMP_DIR="$TEMP_DIR"/"$SLURM_ARRAY_TASK_ID"
mkdir "$TEMP_DIR"
cd "$TEMP_DIR"

########## merge per ind
## merge across callers for each sample
bcftools concat -a /gpool/cfiscus/vitis_svs/results/delly2/"$SAMP".bcf \
/gpool/cfiscus/vitis_svs/results/lumpy2/"$SAMP"-smoove.genotyped.vcf.gz \
/gpool/cfiscus/vitis_svs/results/manta/"$SAMP".vcf.gz | bcftools view -i 'QUAL>20' | bgzip > merge.vcf.gz

## index
bcftools index -t merge.vcf.gz

## collapse with truvari
truvari collapse -i merge.vcf.gz -o "$SAMP"_merge.vcf -c "$SAMP"_collapsed.vcf -f "$REF" --hap -S 1000000

## mv result to folder
cp "$SAMP"_collapsed.vcf "$OUTDIR"
bgzip "$SAMP"_merge.vcf
bcftools index -t "$SAMP"_merge.vcf.gz
cp "$SAMP"_merge.vc* "$OUTDIR"

rm -r "$TEMP_DIR"
