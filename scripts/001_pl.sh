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
#SBATCH --array=2-7,194-199

## FULL ARRAY 2-198

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
MANTA_INSTALL_PATH=/gpool/cfiscus/bin/manta-1.6.0.centos6_x86_64
PREFIX=$(head -n "$SLURM_ARRAY_TASK_ID" "$LST" | tail -n 1 | cut -f3)

# check which step of pl to enter
if [ "$PREFIX" != "NA" ]
then	
	FILE=$(head -n "$SLURM_ARRAY_TASK_ID" "$LST" | tail -n 1 | cut -f3)
	NAME=$(basename "$FILE")

	# quality and adapter trimming
	java -jar "$TRIMMOMATIC" PE -threads "$THREADS" \
	    "$FILE"-READ1-Sequences.txt.gz \
    	"$FILE"-READ2-Sequences.txt.gz \
    	"$NAME"_1_trimmed_paired.fq.gz "$NAME"_1_unpaired.fq.gz \
    	"$NAME"_2_trimmed_paired.fq.gz "$NAME"_2_unpaired.fq.gz \
    	ILLUMINACLIP:"$ADAPTERSPE":2:30:10 \
    	LEADING:3 TRAILING:3 SLIDINGWINDOW:4:20 MINLEN:60

	# map to genome
	bwa mem -t "$THREADS" -M $REF "$NAME"_1_trimmed_paired.fq.gz \
        "$NAME"_2_trimmed_paired.fq.gz > "$NAME".sam

	# sam to sorted bam
	samtools view -bS "$NAME".sam | samtools sort -T temp - -o "$NAME".bam

	# mark dups
	gatk --java-options "-Xmx32G" MarkDuplicates \
    	-I "$NAME".bam \
    	-O "$NAME".nodups.bam \
    	-M "$NAME".md.metrics.txt

	# add read groups
	gatk --java-options "-Xmx32G" AddOrReplaceReadGroups \
    	-I "$NAME".nodups.bam \
    	-O "$NAME".nodups.rg.bam \
    	--CREATE_INDEX true \
    	-RGID "$SLURM_ARRAY_TASK_ID" \
    	-RGLB "$NAME" \
    	-RGSM "$NAME" \
    	-RGPL Illumina_HiSeq \
    	-RGPU Illumina_HiSeq

	BAM="$NAME".nodups.rg.bam
	cp "$BAM" "$OUTDIR"/bam	
	
else	# already mapped
	# cp bam file to temp dir
	FILE=$(head -n "$SLURM_ARRAY_TASK_ID" "$LST" | tail -n 1 | cut -f4)
	BAM=$(basename "$FILE")
	cp "$FILE" ./

fi

# index	
samtools index "$BAM"

# call SVs with lumpy
smoove call --outdir "$OUTDIR"/lumpy --name "$SLURM_ARRAY_TASK_ID" --fasta "$REF" -p 1 --genotype "$BAM"
	
# call SVs with delly2
delly call -g "$REF" "$BAM" > "$OUTDIR"/delly/"$SLURM_ARRAY_TASK_ID".vcf
	
# call SVs with manta
## mk config
${MANTA_INSTALL_PATH}/bin/configManta.py \
--bam "$BAM" \
--referenceFasta "$REF" \
--runDir ./

## call
./runWorkflow.py -g 32 -j 4

## recover result
cp "$TEMP_DIR"/results/variants/diploidSV.vcf.gz "$OUTDIR"/manta/"$SLURM_ARRAY_TASK_ID".vcf.gz
tabix -p vcf "$OUTDIR"/manta/"$SLURM_ARRAY_TASK_ID".vcf.gz

##########
## cleanup temp dir
rm -r "$TEMP_DIR"
