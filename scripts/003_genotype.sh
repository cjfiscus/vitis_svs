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
#SBATCH --array=2-190%10

## FULL ARRAY 2-190

## software dependencies
### samtools 1.17
### smoove 0.2.8 wrapping lumpy 0.2.13
### delly 1.1.6
### manta 1.6.0
### gatk 4.2.6.1

# env for smoove
PATH=/gpool/cfiscus/bin/miniconda3/bin:$PATH
source activate sv_calling

# initialize temp dir
TEMP_DIR=/gpool/cfiscus/temp/$SLURM_ARRAY_TASK_ID
mkdir -pv "$TEMP_DIR"
echo "$TEMP_DIR"
cd "$TEMP_DIR"

# vars
PATH=/gpool/bin/jre1.8.0_221/bin/:$PATH
PATH=/gpool/cfiscus/bin/gatk-4.2.6.1:$PATH
THREADS=8
LST=/gpool/cfiscus/vitis_svs/data/sample_table.txt
OUTDIR=/gpool/cfiscus/vitis_svs/results
REF=/gpool/cfiscus/b40-14_v2.0/VITVarB40-14_v2.0.pseudomolecules.hap1.fasta
TRIMMOMATIC=/gpool/cfiscus/bin/Trimmomatic-0.39/trimmomatic-0.39.jar
ADAPTERSPE=/gpool/cfiscus/bin/Trimmomatic-0.39/adapters/TruSeq3-PE.fa
SMOOVE_MERGED=/gpool/cfiscus/vitis_svs/results/smoove_merged.sites.vcf.gz
DELLY_MERGED=/gpool/cfiscus/vitis_svs/results/delly_merged.vcf

# check which step of pl to enter
if [ $SLURM_ARRAY_TASK_ID -gt 172 ]
then	
	FILE=$(head -n "$SLURM_ARRAY_TASK_ID" "$LST" | tail -n 1 | cut -f3)
	NAME=$(basename "$FILE")

	BAM="$NAME".nodups.rg.bam
	cp "$OUTDIR"/bam/"$BAM" ./	
	
else	# already mapped
	# cp bam file to temp dir
	FILE=$(head -n "$SLURM_ARRAY_TASK_ID" "$LST" | tail -n 1 | cut -f4)
	BAM=$(basename "$FILE")
	cp "$FILE" ./

fi

# index	
samtools index "$BAM"

# genotype SVs with lumpy
smoove genotype -d -x -p 7 --name "$SLURM_ARRAY_TASK_ID" --outdir "$OUTDIR"/lumpy2 --fasta "$REF" --vcf "$SMOOVE_MERGED" "$BAM"
	
# genotype SVs with delly2
delly call -g "$REF" -v "$DELLY_MERGED" "$BAM" -o "$OUTDIR"/delly2/"$SLURM_ARRAY_TASK_ID".bcf	

##########
## cleanup temp dir
rm -r "$TEMP_DIR"
