#!/bin/bash
#SBATCH --error=script_output/fastqc_output/"%x_error.%j" #if your job fails, the error report will be put in this file
#SBATCH --output=script_output/fastqc_output/"%x_output.%j" #once your job is completed, any final job report comments will be put in this file
#SBATCH --partition=short
#SBATCH --nodes=1
#SBATCH --time=20:00:00
#SBATCH --job-name=fastqc
#SBATCH --mem=3GB
#SBATCH --ntasks=24
#SBATCH --cpus-per-task=2

### USER TO-DO ### 
## 1. Set paths for your project

## LOAD MODULES
module load OpenJDK/19.0.1 ## dependency on NU Discovery cluster 
module load fastqc/0.11.9

## SET PATHS 
raw_path="/work/gmgi/Fisheries/eDNA/NY/raw_data"
out_dir="/work/gmgi/Fisheries/eDNA/NY/QC/fastqc_raw"

## CREATE SAMPLE LIST FOR SLURM ARRAY
### 1. Create list of all .gz files in raw data path
ls -d ${raw_path}/*.gz > ${raw_path}/rawdata

### 2. Create a list of filenames based on that list created in step 1
mapfile -t FILENAMES < ${raw_path}/rawdata

### 3. Create variable i that will assign each row of FILENAMES to a task ID
i=${FILENAMES[$SLURM_ARRAY_TASK_ID]}

## RUN FASTQC PROGRAM 
fastqc ${i} --outdir ${out_dir}
