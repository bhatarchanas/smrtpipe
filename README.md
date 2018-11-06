[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0) [](#lang-us) ![ruby in bioinformatics ftw](https://img.shields.io/badge/Language-ruby-steelblue.svg)


# CCS2 via SMRT pipe
## Using PacBio microbiome data to carry out demultiplexing and to run CCS2  

### Introduction:
SMRT pipe is a tool from PacBio which is useful for secondary analysis of PacBio data. This program helps run lima (for demultiplexing) and CCS2 on microbiome data from PacBio's new Sequel machine. 

### Installation:
SMRT pipe comes installed with the SMRT analysis software suite. No additional installation is required to run this script. 

### Data Prerequisites:
1. Sequencing data from microbiome samples which were pooled and sequenced on the Sequel.
2. Barcodes file with all the barcodes that were used for pooling. File should be in FASTA format. 
3. Sample file with information regarding each sample. 

### Arguments:
  * `SAMPLE_INFO_FILE (-s)` – This is the file which will have a list of all the PacBio jobs which are demutiplexed. The FASTQ files of the jobs given in this list will be extracted and the headers of each FASTQ sequence will be added with additional tags like CCS count and sample information. The header of this file (first row) should have column names corresponding to PB_jobid, data_path, forward_barcode, reverse_barcode and sample_name. These column names HAVE TO BE exactly as is described here because the program initializes data in each column based on these column names. Data in each column is described as follows:  
      1. PB_jobid – The ID number assigned to each job when the data is demultiplexed on SMRT portal.    
      2. data_path – Path to where the demultiplexed data for each job is located.   
      3. forward_barcode – Name of the forward primer used for the samples in the respective job, as given in the PRIMERS_DB file.  
      4. reverse_barcode - Name of the reverse primer used for the samples in the respective job, as given in the PRIMERS_DB file.  
      5. sample_name – This is the name given to each sample. This is the one that is going to be added in the FASTQ sequence header with a tag of “barcodelabel”. So, if you want any information to be kept track of, add it as a sample name. Multiple things can be kept track of in the sample name, separated by a “_”. For example, if I want to keep track of patient ID and sample ID in this location, give it the sample name “Pat123_Samp167” where Pat123 corresponds to the patient ID and Samp167 corresponds to the sample ID. This way all this information will be associated with each sequence and can later be tracked easily. Mandatorily, each forward and reverse barcode pair is given a unique number and this number is also added in the beginning of the “barcodelabel” tag in the fastq file.    
  * OUTPUT_FOLDER_NAME (-o) – Name of the folder in which the FASTQ files (with ccs and sample information in the header) are going to be stored. The name of each FASTQ file in this folder is going to be the same as the sample name given in the SAMPLE_INFO_FILE.   
