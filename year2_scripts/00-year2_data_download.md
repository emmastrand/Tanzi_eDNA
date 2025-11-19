# Year 2 Data download

Reports URL
https://cobb-data.sr.unh.edu/projects/251114_A01346_0194_AH7N3WDRX7_AMP-111425-TanziScienceResearch25-MF/reports

Reads URL
https://cobb-data.sr.unh.edu/projects/251114_A01346_0194_AH7N3WDRX7_AMP-111425-TanziScienceResearch25-MF/reads

Username (in email)  
Password (in email)  

## Computational space

Working on URI's Unity HPC: https://docs.unity.uri.edu/ 

## Run information

Run
251114_A01346_0194_AH7N3WDRX7
Project
AMP-111425-TanziScienceResearch25-MF
Start
2025-11-17 15:03:27
End
2025-11-17 15:03:27
Arguments
251114_A01346_0194_AH7N3WDRX7 -n jeff-samplesheet-redo-11172025-IndexLength10.csv

## Data download 

Download FASTQ files (replace user and pw with correct information)

```
wget -r -np -R "index.html*" --http-user=<user> --http-password=<pw> https://cobb-data.sr.unh.edu/projects/251114_A01346_0194_AH7N3WDRX7_AMP-111425-TanziScienceResearch25-MF/reads
```

This created `/project/pi_hputnam_uri_edu/estrand/Tanzi-eDNA/raw_data/cobb-data.sr.unh.edu/projects/251114_A01346_0194_AH7N3WDRX7_AMP-111425-TanziScienceResearch25-MF/reads`. Moved FQ files to `/project/pi_hputnam_uri_edu/estrand/Tanzi-eDNA/raw_data`

```
mv *.gz /project/pi_hputnam_uri_edu/estrand/Tanzi-eDNA/raw_data
```

Within `emma_strand_uri_edu@login3:/project/pi_hputnam_uri_edu/estrand/Tanzi-eDNA/raw_data/cobb-data.sr.unh.edu/projects/251114_A01346_0194_AH7N3WDRX7_AMP-111425-TanziScienceResearch25-MF/reads/Reports`, moving csv reports to raw data 

```
mv *.csv /project/pi_hputnam_uri_edu/estrand/Tanzi-eDNA/raw_data
mv *.html /project/pi_hputnam_uri_edu/estrand/Tanzi-eDNA/raw_data
```

They already ran fastqc and multiqc for us: `/project/pi_hputnam_uri_edu/estrand/Tanzi-eDNA/raw_data/cobb-data.sr.unh.edu/projects/251114_A01346_0194_AH7N3WDRX7_AMP-111425-TanziScienceResearch25-MF/reads/Reports/additional-reports/fastqc_output` and `/multiqc_output` and `multiqc_report.html`

```
mkdir /project/pi_hputnam_uri_edu/estrand/Tanzi-eDNA/fastqc_raw
mv * /project/pi_hputnam_uri_edu/estrand/Tanzi-eDNA/fastqc_raw

## from multiqc_report directories
mkdir /project/pi_hputnam_uri_edu/estrand/Tanzi-eDNA/multiqc_raw
mv * /project/pi_hputnam_uri_edu/estrand/Tanzi-eDNA/multiqc_raw
mv multiqc_report.html /project/pi_hputnam_uri_edu/estrand/Tanzi-eDNA/multiqc_raw

mkdir /project/pi_hputnam_uri_edu/estrand/Tanzi-eDNA/run_statistics
mv * /project/pi_hputnam_uri_edu/estrand/Tanzi-eDNA/run_statistics
```

