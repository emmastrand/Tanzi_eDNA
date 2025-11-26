# Running ampliseq on this dataset

Instructions here: https://gmgi-fisheries.github.io/resources/eDNA%2012S%20metab/01-Metabarcoding%20ampliseq_12S_Riaz/ . I did this on URI's unity HPC.

### Creating samplesheet 

Create a list of files: 

```
raw_path="/project/pi_hputnam_uri_edu/estrand/Tanzi-eDNA/raw_data"
ls -d ${raw_path}/*.gz > ${raw_path}/rawdata

```

Create samplesheet 

```
## Load libraries 

library(dplyr)
library(stringr)
library(strex) 

### Read in sample sheet 

sample_list <- read.delim2("/project/pi_hputnam_uri_edu/estrand/Tanzi-eDNA/raw_data/rawdata", header=F) %>% 
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

sample_list %>% write.csv("/project/pi_hputnam_uri_edu/estrand/Tanzi-eDNA/metadata/samplesheet.csv", 
                          row.names=FALSE, quote = FALSE)
```


### Running ampliseq

MiFish-U 12S amplicon F: GTCGGTAAAACTCGTGCCAGC  
MiFish-U 12S amplicon R: CATAGTGGGGTATCTAATCCCAGTTTG  

`ampliseq.sh`:

```
#!/usr/bin/env bash
#SBATCH --export=NONE
#SBATCH --nodes=1 --ntasks-per-node=6
#SBATCH --partition=uri-cpu
#SBATCH --no-requeue
#SBATCH --mem=20GB
#SBATCH --time 24:00:00
#SBATCH -o output/"%x_output.%j"
#SBATCH -e output/"%x_error.%j"

## Load Nextflow  
module load conda/latest
conda activate /work/pi_hputnam_uri_edu/conda/envs/nextflow

## Set Nextflow directories to use scratch
out="/project/pi_hputnam_uri_edu/estrand/Tanzi-eDNA/ampliseq_output"
export NXF_WORK=${out}/work
export NXF_TEMP=${out}/temp

# SET PATHS 
metadata="/project/pi_hputnam_uri_edu/estrand/Tanzi-eDNA" 

nextflow run nf-core/ampliseq -resume \
   -profile singularity \
   --input ${metadata}/samplesheet.csv \
   --FW_primer "GTCGGTAAAACTCGTGCCAGC" \
   --RV_primer "CATAGTGGGGTATCTAATCCCAGTTTG" \
   --outdir ${out} \
   --trunclenf 150 \
   --trunclenr 150 \
   --trunc_qmin 15 \
   --sample_inference pseudo \
   --skip_taxonomy \
   --ignore_failed_filtering \
   --ignore_failed_trimming \
   --skip_summary_report_fastqc true
```

Testing in interactive first. Need to update Nextflow 

`Nextflow version 24.10.3 does not match workflow required version: >=24.10.5`

**11-22-2025**: Try conda environment for this. Creating nextflow conda environment

```
module load conda/latest
conda create --prefix /work/pi_hputnam_uri_edu/conda/envs/nextflow openjdk=17 -y

conda activate /work/pi_hputnam_uri_edu/conda/envs/nextflow
cd /work/pi_hputnam_uri_edu/conda/envs/nextflow
curl -s https://get.nextflow.io | bash
chmod +x nextflow
mv nextflow $CONDA_PREFIX/bin/
```

Remove these commands and replace with conda nextflow

```
module purge
module load nextflow/24.10.3
module load apptainer/latest
export NXF_WORK=${out}/nextflow_work
export NXF_TEMP=${out}/nextflow_temp
export NXF_LAUNCHER=${out}/nextflow_launcher
```

I can't seem to get around this issue. I hardly have any filters in there. Do I have the wrong primer?

```
WARN: The following samples had too few reads (<1) after quality filtering with DADA2:
HM2_IT_MF
HM1_IT_MF
HM3_IT_MF
HM5_IT_MF
MRG1_IT_MF
HM4_IT_MF
MRG3_IT_MF
MRG4_IT_MF
MRG2_IT_MF
WML1_IT_MF
WML2_IT_MF
MRG5_IT_MF
WML4_IT_MF
WML5_IT_MF
XB_IT_MF
WML3_IT_MF
Ignoring failed samples and continue!
```

**11-25-2025**: Without any flags I got this to run but a lot of reads are taken out by filtering and merged. There is a default quality median 25 so I'm putting this back in to see if a lower quality retains reads.

**11-25-2025**: I'm trying a trunc length of 150. I still don't understand how the read is 250 bp long when the read could be shorter than that... Let's try.

This worked better but still isn't fish... Using NCBI to blast.