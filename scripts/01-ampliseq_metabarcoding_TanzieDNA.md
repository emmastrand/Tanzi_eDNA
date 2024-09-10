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

MiFish-U 12S amplicon F: GTCGGTAAAACTCGTGCCAGC  
MiFish-U 12S amplicon R: CATAGTGGGGTATCTAATCCCAGTTTG  

This was 2x250 bp sequencing - max length of reads is 250 bp.

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
   --RV_primer "CATAGTGGGGTATCTAATCCCAGTTTG" \
   --outdir ${output_dir} \
   --trunc_qmin 25 \
   --max_len 200 \
   --max_ee 2 \
   --sample_inference pseudo \
   --skip_taxonomy \
   --ignore_failed_filtering \
   --ignore_failed_trimming
```

Possible additions: 
- `--min_len_asv 100 --max_len_asv 115`: The target should be ~163-185  
- `--trunclenf 200 --trunclenr 200`: 200-230 but the script above is basing this on quality so leave out for now.

## Step 4: Blast ASV sequences against MiFish database

https://github.com/billzt/MiFish/tree/main

This uses MiFish as the first pass database. Use NCBI as next step?

Create conda environment with MiFish set-up:

```
source ~/../../work/gmgi/miniconda3/bin/activate
conda create -n MiFish python==3.9.13
conda activate MiFish
pip3 install numpy==1.23.1
pip3 install scikit-bio==0.5.6
pip3 install PyQt5==5.15.7
pip3 install ete3==3.1.2
pip3 install duckdb==0.6.1
pip3 install XlsxWriter==3.0.3
pip3 install cutadapt==4.1
pip3 install biopython==1.79
git clone https://github.com/billzt/MiFish.git
cd MiFish
python3 setup.py develop
mifish -h
```

#### Update Mitofish database 

MitoFish download: Updated /work/gmgi/databases/12S/MitoFish to 4.04 Sept 2024 

Check Mitofish webpage (https://mitofish.aori.u-tokyo.ac.jp/download/) for the most recent database version number. Compare to the `work/gmgi/databases/12S/reference_fasta/12S/Mitofish/` folder. If needed, update Mitofish database:

```
## download db 
wget https://mitofish.aori.u-tokyo.ac.jp/species/detail/download/?filename=download%2F/complete_partial_mitogenomes.zip  

## unzip 
unzip 'index.html?filename=download%2F%2Fcomplete_partial_mitogenomes.zip'

## clean headers 
awk '/^>/ {print $1} !/^>/ {print}' mito-all > Mitofish_v4.04.fasta

## remove excess files 
rm mito-all* 
rm index*

## make NCBI db 
## make sure fisheries_eDNA conda environment is activated or module load ncbi-blast+/2.13.0
conda activate fisheries_eDNA
makeblastdb -in Mitofish_v4.04.fasta -dbtype nucl -out Mitofish_v4.04.fasta -parse_seqids

conda activate MiFish
```

### Taxonomic ID script 

I ended up doing this in the command line instead of sbatch. I got 0 results from the Mitofish search... and summary report says sequences are bacterial origin.. Did we only catch 16S with this protocol? MiFish is known to do this.. 

```
# Activate conda environment
source ~/../../work/gmgi/miniconda3/bin/activate
conda activate fisheries_eDNA

# SET PATHS 
ASV_fasta="/work/gmgi/Fisheries/eDNA/NY/results/dada2/ASV_seqs.fasta"
out="/work/gmgi/Fisheries/eDNA/NY/TaxID"

gmgi="/work/gmgi/databases/12S/GMGI"
mito="/work/gmgi/databases/12S/Mitofish"
taxonkit="/work/gmgi/databases/taxonkit"

#### DATABASE QUERY ####
## Mitofish database 
blastn -db ${mito}/*.fasta -query ${ASV_fasta} -out ${out}/BLASTResults_Mito.txt -max_target_seqs 30 -perc_identity 90 -qcov_hsp_perc 95 -outfmt '6  qseqid   sseqid  pident   length   mismatch gapopen  qstart   qend  sstart   send  evalue   bitscore'

### NCBI database 
blastn -remote -db nt -query ${ASV_fasta} -out ${out}/BLASTResults_NCBI.txt -max_target_seqs 10 -perc_identity 90 -qcov_hsp_perc 95 -outfmt '6  qseqid   sseqid   sscinames   staxid pident   length   mismatch gapopen  qstart   qend  sstart   send  evalue   bitscore'

############################

#### TAXONOMIC CLASSIFICATION #### 
## creating list of staxids from all three files 
awk -F $'\t' '{ print $4}' ${out}/BLASTResults_NCBI.txt | sort -u > ${out}/NCBI_sp.txt

## annotating taxid with full taxonomic classification
cat ${out}/NCBI_sp.txt | ${taxonkit}/taxonkit reformat -I 1 -r "Unassigned" > ${out}/NCBI_taxassigned.txt
```