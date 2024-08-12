# Metabarcoding workflow for 12S amplicon sequencing

Scripts to run:
1. 00-fastqc.sh
2. 00-multiqc.sh
3. 01a-metadata.R
4. 01b-ampliseq.sh
5. 02-taxonomicID.sh

## Step 1: Assess quality of raw data

`00-fastqc.sh`:

```
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
```

To run:
- Start slurm array (e.g., with 30 files) = `sbatch --array=0-29 00-fastqc.sh`

Notes:

- This is going to output many error and output files. After job completes, use `cat *output.* > ../fastqc_output.txt` to create one file with all the output and `cat *error.* > ../fastqc_error.txt` to create one file with all of the error message outputs.
- Within the out_dir output folder, use `ls *html | wc` to count the number of html output files (1st/2nd column values). This should be equal to the --array range used and the number of raw data files. If not, the script missed some input files so address this before moving on.

## Step 2: Visualize quality of raw data

`00-multiqc.sh`

```
## activate conda environment 
source ~/../../work/gmgi/miniconda3/bin/activate
conda activate haddock_methylation

## SET PATHS 
## fastqc_output = output from 00-fastqc.sh; fastqc program
fastqc_output="/work/gmgi/Fisheries/eDNA/NY/QC/fastqc_raw"
multiqc_dir="/work/gmgi/Fisheries/eDNA/NY/QC/multiqc_raw"

## RUN MULTIQC 
multiqc --interactive ${fastqc_output} -o ${multiqc_dir} --filename multiqc_raw.html
```

## Step 3: Ampliseq

### Metadata sheet 

**Create samplesheet sheet for ampliseq**

This file indicates the sample ID and the path to R1 and R2 files. Below is a preview of the sample sheet used in this test. File created on RStudio Interactive on Discovery Cluster using (`create_metadatasheets.R`).
- sampleID (required): Unique sample IDs, must start with a letter, and can only contain letters, numbers or underscores (no hyphons!).  
- forwardReads (required): Paths to (forward) reads zipped FastQ files  
- reverseReads (optional): Paths to reverse reads zipped FastQ files, required if the data is paired-end  
- run (optional): If the data was produced by multiple sequencing runs, any string  

*This is an R script, not slurm script. Open RStudio interactive on Discovery Cluster to run this script.*

Prior to running R script, use the rawdata file created for the fastqc slurm array from within the raw data folder to create a list of files. 

```
### Create samplesheet sheet for Tanzi eDNA project 
library(dplyr)
library(stringr)
library(strex)

### Read in sample sheet 
sample_list <- read.delim2("/work/gmgi/Fisheries/eDNA/NY/raw_data/rawdata", header=F) %>% 
  dplyr::rename(forwardReads = V1) %>%
  mutate(sampleID = str_after_nth(forwardReads, "data/", 1),
         sampleID = str_before_nth(sampleID, "_S", 1))

# creating sample ID 
sample_list$sampleID <- gsub("-", "_", sample_list$sampleID)

# keeping only rows with R1
sample_list <- filter(sample_list, grepl("R1", forwardReads, ignore.case = TRUE))

# duplicating column 
sample_list$reverseReads <- sample_list$forwardReads

# replacing R1 with R2 in only one column 
sample_list$reverseReads <- gsub("R1", "R2", sample_list$reverseReads)

# rearranging columns 
sample_list <- sample_list[,c(2,1,3)]

# saving file 
sample_list %>% write.csv("/work/gmgi/Fisheries/eDNA/NY/metadata/samplesheet.csv", 
                          row.names=FALSE, quote = FALSE)
```


### Ampliseq 

12S primer sequences (required)
Below is what we used for 12S amplicon sequencing at UNH (MiFish). Ampliseq will automatically calculate the reverse compliment and include this for us.

MiFish 12S amplicon F: GTCGGTAAAACTCGTGCCAGC
MiFish 12S amplicon R: GTTTGACCCTAATCTATGGGGTGATAC

Run nf-core/ampliseq (Cutadapt & DADA2):

`01-ampliseq.sh`:

```
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
   --trunclenf 20 \
   --trunclenr 20 \
   --trunc_qmin 25 \
   --max_len 200 \
   --max_ee 2 \
   --min_len_asv 100 \
   --max_len_asv 115 \
   --sample_inference pseudo \
   --skip_taxonomy \
   --ignore_failed_filtering \
   --ignore_failed_trimming
```

Stopped here:  
- Confirm what primer sequences were used?
- Lab protocol - confirm gel images and quality of DNA extracts?