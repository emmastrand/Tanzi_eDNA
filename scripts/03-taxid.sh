#!/bin/bash
#SBATCH --error=output_messages/"%x_error.%j" #if your job fails, the error report will be put in this file
#SBATCH --output=output_messages/"%x_output.%j" #once your job is completed, any final job report comments will be put in this file
#SBATCH --partition=short
#SBATCH --nodes=1
#SBATCH --time=20:00:00
#SBATCH --job-name=tax_ID
#SBATCH --mem=30GB
#SBATCH --ntasks=24
#SBATCH --cpus-per-task=2

# Activate conda environment
source /work/gmgi/miniconda3/bin/activate
conda activate fisheries_eDNA

# SET PATHS 
ASV_fasta="/work/gmgi/Fisheries/eDNA/NY/results/dada2"
out="/work/gmgi/Fisheries/eDNA/NY/TaxID"

gmgi="/work/gmgi/databases/12S/GMGI"
mito="/work/gmgi/databases/12S/Mitofish"
ncbi="/work/gmgi/databases/ncbi/nt"
taxonkit="/work/gmgi/databases/taxonkit"

#### TAXONOMIC CLASSIFICATION #### 
## creating list of staxids from all three files 
awk -F $'\t' '{ print $4}' ${out}/BLASTResults_NCBI.txt | sort -u > ${out}/NCBI_sp.txt

## annotating taxid with full taxonomic classification
cat ${out}/NCBI_sp.txt | ${taxonkit}/taxonkit reformat -I 1 -r "Unassigned" > ${out}/NCBI_taxassigned.txt
