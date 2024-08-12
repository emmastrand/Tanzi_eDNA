#!/bin/bash
#SBATCH --error=output_messages/"%x_error.%j" #if your job fails, the error report will be put in this file
#SBATCH --output=output_messages/"%x_output.%j" #once your job is completed, any final job report comments will be put in this file
#SBATCH --partition=short
#SBATCH --nodes=1
#SBATCH --time=20:00:00
#SBATCH --job-name=ampliseq
#SBATCH --mem=70GB
#SBATCH --ntasks=24
#SBATCH --cpus-per-task=2

### USER TO-DO ### 
## 1. Set paths for project 
## 2. Adjust SBATCH options above (time, mem, ntasks, etc.) as desired  
## 3. Fill in F and R primer information (no reverse compliment)
## 4. Adjust parameters as needed (below is Fisheries team default for 12S)

# LOAD MODULES
module load singularity/3.10.3
module load nextflow/23.10.1

# SET PATHS 
metadata="/work/gmgi/Fisheries/eDNA/NY/metadata" 
output_dir="/work/gmgi/Fisheries/eDNA/NY/results"

nextflow run nf-core/ampliseq -resume \
   -profile singularity \
   --input ${metadata}/samplesheet.csv \
   --FW_primer "GTCGGTAAAACTCGTGCCAGC" \
   --RV_primer "GTTTGACCCTAATCTATGGGGTGATAC" \
   --outdir ${output_dir} \
   --trunclenf 100 \
   --trunclenr 100 \
   --trunc_qmin 25 \
   --max_len 200 \
   --max_ee 2 \
   --min_len_asv 100 \
   --max_len_asv 115 \
   --sample_inference pseudo \
   --skip_taxonomy \
   --ignore_failed_trimming
