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
DATADIR=/gpool/cfiscus/vitis_svs/data
OUTDIR=/gpool/cfiscus/vitis_svs/results
REF=/gpool/cfiscus/b40-14_v2.0/VITVarB40-14_v2.0.pseudomolecules.hap1.fasta

# merge ind vcf for smoove
smoove paste --name "$OUTDIR"/svs_lumpy_raw.vcf "$OUTDIR"/lumpy2/*-smoove.genotyped.vcf.gz

# merge ind vcf for delly
bcftools merge -m id "$OUTDIR"/delly2/*.bcf > "$OUTDIR"/svs_delly_raw.vcf

# merge ind vcf for manta
bcftools merge -m id "$OUTDIR"/manta/*.vcf.gz > "$OUTDIR"/svs_manta_raw.vcf

# merge all sets with SURVIVOR
SURVIVOR merge "$DATADIR"/sample_files 1000 2 1 1 0 50 "$OUTDIR"/svs_allcallers_raw.vcf

# filter with SURVIVOR
SURVIVOR filter "$OUTDIR"/svs_allcallers_raw.vcf "$DATADIR"/VITVarB40-14_v2.0.repeats.bed 50 -1 0.01 3 "$OUTDIR"/svs_filtered.vcf
