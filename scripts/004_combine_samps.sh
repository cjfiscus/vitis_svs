#!/bin/bash

#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=8G
#SBATCH --output=com%j.stdout
#SBATCH --error=com%j.stderr
#SBATCH --mail-user=cfiscus@uci.edu
#SBATCH --mail-type=ALL
#SBATCH --time=1-00:00:00
#SBATCH --job-name="comb"
#SBATCH -p gcluster
#SBATCH --array=2-39

# software dependencies
## bcftools

## software
PATH=/gpool/bin/samtools-1.10/bin:$PATH
PATH=/gpool/cfiscus/bin:$PATH
PATH=/gpool/bin/bcftools-1.10.2/bin:$PATH

## set vars
LST=/gpool/cfiscus/vitis_svs/data/combine.txt
ID=$(head -n "$SLURM_ARRAY_TASK_ID" "$LST" | tail -n 1 | cut -f1)
PROG=$(head -n "$SLURM_ARRAY_TASK_ID" "$LST" | tail -n1 | cut -f2)
FILES=$(head -n "$SLURM_ARRAY_TASK_ID" "$LST" | tail -n 1| cut -f3)
expression=($FILES)
##########

# mk tempdir
TEMP_DIR=/gpool/cfiscus/temp/$SLURM_ARRAY_TASK_ID
mkdir -pv "$TEMP_DIR"
echo "$TEMP_DIR"
cd "$TEMP_DIR"

# set sample name
echo "$ID" > "$ID"_samp.txt

# combine samples
if [ $PROG == "lumpy" ]; then
OUT=/gpool/cfiscus/vitis_svs/results/lumpy2/"$ID"-smoove.genotyped.vcf.gz

## reheader
for f in "${expression[@]}"
do
	echo "$f"
	NAME=$(basename "$f")
	bcftools reheader -s "$ID"_samp.txt "$f" > "$NAME".temp 
	mv "$NAME".temp "$NAME"

	tabix -f "$NAME"

	mv "$f" /gpool/cfiscus/vitis_svs/results/combined/lumpy
	mv "$f".csi /gpool/cfiscus/vitis_svs/results/combined/lumpy

done

## concat
bcftools concat -a --no-version --rm-dups all *.vcf.gz -O z -o "$OUT"
tabix -C "$OUT"

elif [ "$PROG" == "delly" ]; then
OUT=/gpool/cfiscus/vitis_svs/results/delly2/"$ID".bcf

## reheader
for f in "${expression[@]}"
do
	echo "$f"
	NAME=$(basename "$f")
	bcftools reheader -s "$ID"_samp.txt "$f" > "$NAME".temp 
	mv "$NAME".temp "$NAME"

	tabix "$NAME"
	
	mv "$f" /gpool/cfiscus/vitis_svs/results/combined/delly
	mv "$f".csi /gpool/cfiscus/vitis_svs/results/combined/delly

done

## concat
bcftools concat -a --no-version --rm-dups all *.bcf -O b -o "$OUT"
tabix "$OUT"

else # manta

OUT=/gpool/cfiscus/vitis_svs/results/manta/"$ID".vcf.gz

## reheader
for f in "${expression[@]}"
do
	echo "$f"
	cp "$f" ./
	NAME=$(basename "$f")
	bcftools reheader -s "$ID"_samp.txt "$f" > "$NAME".temp 
	mv "$NAME".temp "$NAME"

	tabix -f "$NAME"

	mv "$f" /gpool/cfiscus/vitis_svs/results/combined/manta
	mv "$f".tbi /gpool/cfiscus/vitis_svs/results/combined/manta
done

## concat
bcftools concat -a --no-version --rm-dups all *.vcf.gz -O z  -o "$OUT"
tabix "$OUT"

fi
