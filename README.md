
# SBCaptureSeq README
Last modified 2016-05-24

## Requirements

### Minimum hardware specs
64-bit architecture, 8 GB RAM, 20 GB disk space, Intel Core i5 processor

### Tested software configurations
MacOS 10.9+ with Xcode 5+ and bash 3.2+

RHEL 6.5, 6.6, 6.7 with gcc/g++ 4.4+ and bash 4.1+

## Installation
The SBCaptureSeq analysis workflow can be installed using the automated script (```install.sh```). 

The script installs Bowtie 2.2.5, Samtools 0.1.19, Tabix 0.2.6, and Python 2.7, and custom python code to the ```$HOME/nnlab/sbcapseq``` directory. It additionally downloads mm9 fastq sequences, generates an mm9+pT2/Onc2 reference, and indexes the reference. The entire installation process takes about three hours, with the bulk of time devoted to indexing. 

You should run the installer script from the a bash session (in your terminal of choice) so you can track it's progress. To execute the installer from the command line, navigate to the directory containing the installer script, then run:

```
bash install.sh
```

## Obtaining a toy SBCaptureSeq dataset
If the file ```sbcaptureseq-toy.bam``` is not contained with this code, you can download a copy of the dataset from [Figshare](https://figshare.com/s/b5e1c6d3a14edc61c6b0). This dataset will be useful for working through the tutorial. The file is in bam format and is about 30MB in size. 

## Tutorial

###Add sbcapseq toolbox to system path
Before running any of the subsequent steps, open a bash session, then make sure the code you installed is in your system path. Simply copy and paste the following command into your terminal: 

```
export PATH=$HOME/nnlab/sbcapseq/bin:$PATH
```

After doing this, you can invoke the SBCapSeq scripts from any working directory while in your current bash session. Note that ```$HOME``` and ```$PATH``` are variables already predefined in the bash environment. 

###Convert data to FASTQ format from BAM format
Ion Torrent data can be exported in the BAM or FASTQ formats. Since BAM can store flow information, it is a recommended format for Ion Torrent data so you'll likely be dealing with this. However, the SBCaptureSeq workflow does not utilize flow information, and works from the FASTQ format. If you are starting with BAM formatted data, you can use samtools with the ```sam2fastq.py``` script to convert the sequences to FASTQ. Navigate to the directory containing the BAM file you downloaded with this toolbox, then run:

```
samtools view sbcapseq-toy.bam | sam2fastq.py - > sbcapseq-toy.fastq
```

This will produce a FASTQ file, ```sbcapseq-toy.fastq``` in your current working directory suitable for downstream analysis.

### Map sequencing reads to TA sites in mouse
Sequences are mapped to TA sites using the ```fastq2tas.py``` script. Run the following command from the directory containing the FASTQ file you want to analyze:

```
fastq2tas.py -n toy --verbose $HOME/nnlab/sbcapseq/srv sbcapseq-toy.fastq
```

By default, this function will create a folder with a name similar to the input FASTQ file (sans extension). TA insertions will be written to a tab-delimited text file. In this file, each row is a TA insertion site, and the columns represent the following: 

* Columns 1-3: the position of the TA site in the mouse genome 
* Column 4: the dataset to which the insertions are associated
* Column 5: the maximum read length in bases mapped to the left and right side of the TA site
* Column 6: the read depth on the left and right side of the TA site
* Column 7: the unique read/fragment depth on the left and right side of the TA site
* Column 8: the transposon insertion orientation with respect to the chromosome, where '+' is forward and '-' is reverse. 

This script takes an optional argument, ```-n```, which allows the user to change the dataset name. If the option is not specified, then sequencing run ID (embedded in the fastq sequence headers) is used.

### Post-process sites and store them in BED format
The final step is to convert the TA sites into the BED format, as this can be loaded into various genome browsers and superimposed with gene/transcript annotations for and used in downstream analysis. To convert the TA sites to BED format, run the following command:

```
tas2bed.py -f reads sbcapseq-toy/insertions.txt | maskbed.py $HOME/nnlab/sbcapseq/srv/protonMaskSites.bed - > sbcapseq-toy/insertions.bed
```

The ```tas2bed.py``` script calculates calculates a single read-depth score for each site and outputs the results in BED format. In this format, each row represents a TA insertion site, and the columns represent the following:

* Columns 1-3: the position of the TA site in the mouse genome
* Column 4: the dataset to which the insertions are associated, plus additional characteristics about the TA site.
* Column 5: the total read depth at the TA site
* Column 6: the transposon insertion orientation with respect to the chromosome

The ```tas2bed.py``` script can be called with a few different options. if ```-f fragments``` is used, sequence fragments will be reported instead of reads. Setting the length filter to remove reads with less than 25 bases (e.g. ```-l 25```) can help to reduce possible noisy results, as can setting the depth filter (e.g. ```-s 10```). These parameters can be used to filter out low frequency TA sites that may not reproduce adequately across different experiments, and can be set based on empirical knowledge. 

The ```maskbed.py``` script masks the bedfile for sites that are known hotspots. These hotspots were determined empirically by looking for sites that overlapped across different experiments. 
