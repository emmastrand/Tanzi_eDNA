# Running blast on the ASV output 

Barrnap classified 82 ( 43.39 %) ASVs as most similar to Bacteria, 0 ( 0 %) ASVs to Archea, 104 ( 55.03 %) ASVs to Mitochondria, 0 ( 0 %) ASVs to Eukaryotes, and 3 ( 1.59 %) were below similarity threshold to any kingdom.

189 amplicon sequencing variants (ASVs)

Create conda environment: `conda create --prefix /work/pi_hputnam_uri_edu/conda/envs/blast -c bioconda -c conda-forge blast`

### Mitofish 

Copied old Mitofish database from NU to URI: `/project/pi_hputnam_uri_edu/estrand/databases/Mitofish`

`nano blast_mitofish.sh`

```
#!/usr/bin/env bash
#SBATCH --export=NONE
#SBATCH --nodes=1 --ntasks-per-node=6
#SBATCH --partition=uri-cpu
#SBATCH --no-requeue
#SBATCH --mem=10GB
#SBATCH --time 12:00:00
#SBATCH -o output/"%x_output.%j"
#SBATCH -e output/"%x_error.%j"

## Activate blast environment 
module load conda/latest
conda activate /work/pi_hputnam_uri_edu/conda/envs/blast

# SET PATHS 
ASV_fasta="/project/pi_hputnam_uri_edu/estrand/Tanzi-eDNA/ampliseq_output/dada2"
out="/project/pi_hputnam_uri_edu/estrand/Tanzi-eDNA"

mito="/project/pi_hputnam_uri_edu/estrand/databases/Mitofish"

## Mitofish database 
blastn -db ${mito}/*.fasta \
   -query ${ASV_fasta}/ASV_seqs.fasta \
   -out ${out}/BLASTResults_Mito.txt \
   -max_target_seqs 10 -perc_identity 100 -qcov_hsp_perc 95 \
   -outfmt '6  qseqid   sseqid  pident   length   mismatch gapopen  qstart   qend  sstart   send  evalue   bitscore'
```

This file came up empty.... But the program seemed to work. 

### Blast 

I added the fasta file `/projects/gmgi/Fisheries/eDNA/Tanzi_eDNA/ASV_seqs.fasta` to NU so I can blast it with nt database.

`nano blast.sh`

```
#!/bin/bash
#SBATCH --error="%x_error.%j" #if your job fails, the error report will be put in this file
#SBATCH --output="%x_output.%j" #once your job is completed, any final job report comments will be put in this file
#SBATCH --partition=short
#SBATCH --nodes=1
#SBATCH --time=20:00:00
#SBATCH --job-name=tax_ID
#SBATCH --mem=10GB
#SBATCH --ntasks=6
#SBATCH --cpus-per-task=2

# Activate conda environment
source /projects/gmgi/miniconda3/bin/activate fisheries_eDNA

# SET PATHS 
ASV_fasta="/projects/gmgi/Fisheries/eDNA/Tanzi_eDNA/ASV_seqs.fasta"
out="/projects/gmgi/Fisheries/eDNA/Tanzi_eDNA"

ncbi="/projects/gmgi/databases/ncbi/nt"
taxonkit="/projects/gmgi/databases/taxonkit"

#### DATABASE QUERY ####
### NCBI database 
blastn -db ${ncbi}/"nt" \
   -query ${ASV_fasta}/ASV_seqs.fasta \
   -out ${out}/BLASTResults_NCBI.txt \
   -max_target_seqs 10 -perc_identity 100 -qcov_hsp_perc 95 \
   -outfmt '6  qseqid   sseqid   sscinames   staxid pident   length   mismatch gapopen  qstart   qend  sstart   send  evalue   bitscore'

############################

#### TAXONOMIC CLASSIFICATION #### 
## creating list of staxids from all three files 
awk -F $'\t' '{ print $4}' ${out}/BLASTResults_NCBI.txt | sort -u > ${out}/NCBI_sp.txt

## annotating taxid with full taxonomic classification
cat ${out}/NCBI_sp.txt | ${taxonkit}/taxonkit reformat -I 1 -r "Unassigned" > ${out}/NCBI_taxassigned.txt
```
