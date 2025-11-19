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

sample_list %>% write.csv("/work/gmgi/Fisheries/eDNA/NY/metadata/samplesheet.csv", 
                          row.names=FALSE, quote = FALSE)