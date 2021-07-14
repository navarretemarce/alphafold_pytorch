#!/bin/bash

helpFunction()
{
   echo ""
   echo "Usage: feature.sh -t TARGET -d TARGET_DIR"
   echo -e "\t-t Name of the target protein (.seq extension is required)"
   echo -e "\t-d Name of the directory where the portein seq is located"
   exit 1 # Exit script after printing help
}

while getopts "t:d:" opt
do
   case "$opt" in
      t ) TARGET="$OPTARG" ;;
      d ) TARGET_DIR="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$TARGET" ] || [ -z "$TARGET_DIR" ] 
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

echo $TARGET
echo $TARGET_DIR

TARGET_SEQ="${TARGET_DIR}/${TARGET}.seq" # fasta format
PLMDCA_DIR="plmDCA/plmDCA_asymmetric_v2/"
OUTPUT_DIR="${TARGET}_out"

# generate domain crops from target seq
python3 feature.py -s $TARGET_SEQ -c

for domain in ${TARGET_DIR}/*.seq; do
	out=${domain%.seq}
	echo "Generate MSA files for ${out}"
	hhblits -cpu 16 -i ${out}.seq -d databases/uniclust30_2018_08/uniclust30_2018_08 -oa3m ${out}.a3m -ohhm ${out}.hhm -n 3
	reformat.pl ${out}.a3m ${out}.fas
	psiblast -subject ${out}.seq -in_msa ${out}.fas -out_ascii_pssm ${out}.pssm
done

# make target features data and generate ungap target aln file for plmDCA
python3 feature.py -s $TARGET_SEQ -f -o $OUTPUT

cd $PLMDCA_DIR
for aln in ../../${TARGET_DIR}/*.aln; do
	echo "calculate plmDCA for $aln"
	octave plmDCA.m $aln
done
cd -

# run again to update target features data
python3 feature.py -s $TARGET_SEQ -f -o $OUTPUT
