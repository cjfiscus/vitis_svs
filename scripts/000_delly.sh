#!/bin/bash -l

#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --mem=32G
#SBATCH --output=delly_%j.stdout
#SBATCH --error=delly_%j.stderr
#SBATCH --mail-user=cfiscus@uci.edu
#SBATCH --mail-type=ALL
#SBATCH --time=5-00:00:00
#SBATCH --job-name="delly"
#SBATCH -p gcluster

TEMP_DIR=/gpool/cfiscus/temp/$RANDOM
mkdir -pv "$TEMP_DIR"
echo "$TEMP_DIR"
cd "$TEMP_DIR"

BAM=4R157-L8-P04-TAGGCATG-TCGCATAA_vs_vari_v2.0.hap1.q10.sorted.nodup.rg.bam
OUTDIR=/gpool/cfiscus/sv_test/results/delly
REF=/gpool/cfiscus/b40-14_v2.0/VITVarB40-14_v2.0.pseudomolecules.hap1.fasta

# cp bam to temp
cd "$TEMP_DIR"
cp /gpool/amc/arizonica/4_picard/hap1/rgs/"$BAM" ./

# index
samtools index "$BAM"

# delly call per samp
delly call -g "$REF" "$BAM" > "$OUTDIR"/temp.vcf
