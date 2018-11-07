[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0) [](#lang-us) ![ruby in bioinformatics ftw](https://img.shields.io/badge/Language-ruby-steelblue.svg)


# CCS2 via SMRT pipe
## Using PacBio microbiome data to carry out demultiplexing and to run CCS2  

### Introduction:
SMRT pipe is a tool from PacBio which is useful for secondary analysis of PacBio data. This program helps run lima (for demultiplexing) and CCS2 on microbiome data from PacBio's new Sequel machine. 

### Installation:
SMRT pipe comes installed with the SMRT analysis software suite. No additional installation is required to run this script. 

### Data Prerequisites:
1. Sequencing data from microbiome samples which were pooled and sequenced on the Sequel.
2. Barcodes file with all the barcodes that were used for pooling. File should be in FASTA format. This script only works for symmetric barcodes. 
3. Sample file with information regarding each sample. 

### Arguments:
  * `SMRTPIPE (-p)` - The path where smrtpipe is located. Use full path, avoid relative paths.
  * `OUTDIR (-o) ` - Path to where you want your result files to be stored.
  * `SAMPLE_INFO_FILE (-s)` – This is the file which will have a list of all the PacBio jobs which are to be demutiplexed and run thorugh CCS2. The header of this file (first row) should have column names corresponding to pool_id, path_for_lima, barcode, and sample. These column names HAVE TO BE exactly as is described here because the program initializes data in each column based on these column names. Data in each column is described as follows:  
      1. pool_id – The name of each pool, i.e., all the samples pooled togteher into one set will have the same pool_id.    
      2. path_for_lima – Path to where the subreadset.xml file is located for this particular pool. This is the path that is listed as "Data path" on SMRT link. 
      3. barcode – Name of the barcode used for this sample, can only use symmetirc barcodes at this point. 
      4. sample – This is the name given to each sample. This is the one that is going to be added in the FASTQ sequence header with a tag of “barcodelabel”. So, if you want any information to be kept track of, add it as a sample name. Multiple things can be kept track of in the sample name, separated by a “_”. For example, if I want to keep track of patient ID and sample ID in this location, give it the sample name “Pat123_Samp167” where Pat123 corresponds to the patient ID and Samp167 corresponds to the sample ID. This way all this information will be associated with each sequence and can later be tracked easily.   
  * `BARCODE_FILE (-b)` - A FASTA file with all the barcode sequences.

### Usage:
Run the smrtpipe.rb script along with the arguments that are required as input.
`ruby smrtpipe.rb -p xx/bin/pbsmrtpipe -s sample_key.txt -o out_dir_name -b pacbio_barcodes_96.fasta`
