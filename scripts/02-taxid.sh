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

#### DATABASE QUERY ####
### NCBI database 
blastn -db ${ncbi}/"nt" \
   -query ${ASV_fasta}/ASV_seqs.fasta \
   -out ${out}/BLASTResults_NCBI.txt \
   -max_target_seqs 10 -perc_identity 100 -qcov_hsp_perc 95 \
   -outfmt '6  qseqid   sseqid   sscinames   staxid pident   length   mismatch gapopen  qstart   qend  sstart   send  evalue   bitscore' \
   -num_threads 4
