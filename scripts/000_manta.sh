#!/bin/bash -l

#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --mem=32G
#SBATCH --output=manta_%j.stdout
#SBATCH --error=manta_%j.stderr
#SBATCH --mail-user=cfiscus@uci.edu
#SBATCH --mail-type=ALL
#SBATCH --time=5-00:00:00
#SBATCH --job-name="manta"
#SBATCH -p gcluster

TEMP_DIR=/gpool/cfiscus/temp/$RANDOM
mkdir -pv "$TEMP_DIR"
echo "$TEMP_DIR"
cd "$TEMP_DIR"

BAM=4R157-L8-P04-TAGGCATG-TCGCATAA_vs_vari_v2.0.hap1.q10.sorted.nodup.rg.bam
OUTDIR=/gpool/cfiscus/sv_test/results/delly
REF=/gpool/cfiscus/b40-14_v2.0/VITVarB40-14_v2.0.pseudomolecules.hap1.fasta
MANTA_INSTALL_PATH=/gpool/cfiscus/bin/manta-1.6.0.centos6_x86_64

# cp bam to temp
cd "$TEMP_DIR"
cp /gpool/amc/arizonica/4_picard/hap1/rgs/"$BAM" ./

# index
samtools index "$BAM"

# manta call per samp
${MANTA_INSTALL_PATH}/bin/configManta.py \
--bam "$BAM" \
--referenceFasta "$REF" \
--runDir ./

./runWorkflow.py -g 32 -j 8

## cp output
cp diploidSV.vcf.gz /gpool/cfiscus/sv_test/results/manta/temp.vcf.gz
