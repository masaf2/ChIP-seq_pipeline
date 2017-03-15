# MANUAL pipeline_ChIP-seq
2015-09-08

Marianne S. Felix

marianne.sabourin-felix@hotmail.com
---------------------------------------

1. INTRODUCTION
2. WARNINGS
3. SOFTWARE DEPENDECIES
4. FILES REQUIREMENTS
5. HOW TO USE IT
6. PRECONDITIONS
7. OUTPUT FILES
8. HOW IT WORKS

## INTRODUCTION

This script process raw ChIP-seq data into aligned BAM files.

## WARNINGS

Caution, this script was tested only on Linux 14.04 LTS distribution and is
provided "as is", without warranty.

This script works only with SINGLE END files.

## SOFTWARE DEPENDENCIES

This script requires the following softwares :

 - SRA Toolkit
 - Bedtools
 - FastQC
 - Trimmomatic-0.33
 - Bowtie2
 - Samtools

## FILES REQUIREMENTS

The input file format can be either in FASTQ, SAM, BAM, SRA or FASTQ.GZ. One can
process as many file as wanted but one must consider the storage space on the
device (foresee four times the space of the file). Then, the reference genome
must be indexed. To do so, run the following command :

bowtie2-build -f genomeFile.fa genomeName
  or
bowtie2-buil -f genomeChr1.fa,genomeChr2.fa,genomeChr3.fa genomeName

  where genomeChr1.fa,...,genomeChr3.fa is the list of genome files.

## HOW TO USE IT

[1]  One must change the access permission of the script as follows :

      chmod +x pipeline_ChIP-seq.sh

[2]  Open a new screen :

      screen -S screenName

 Here is the list of the most used command of the screen :
 
   Create a screen : screen -S screenName
   Close           : Ctrl + a, Ctrl + d
   List            : screen -ls
   Resume          : screen -r screenName
   Delete          : screen -S screenName -X quit

[3]  Run the script into the open screen :

      ./pipeline_ChIP-seq.sh

[4]  Choose an option between the three :

       1 . Help/Manual
       2 . Launch pipeline
       3 . Quit

      The first option display this manual. The second option launch the pipeline
      and the third option close the program. For the rest of this section, we
      assume that the option two is chosen.

[5]  Enter either F if you want to process one file or D for a folder if you
     want to process many files followed by [ENTER].

[6]  Enter your filename or folder name followed by [ENTER].

      e.g.: ../relative/path/to/file.bam

[7]  Enter path to the indexed reference genome basename, followed by [ENTER]. 

      e.g.: for Mm10.1.bt2 etc. enter : /path/to/index/Mm10

[8]  Type the number of thread(s) you want to use (for trimmomatic and Bowtie2),
     followed by [ENTER].

> If the analysis are made on a personal computer, 1 thread is recommended to ensure the smooth running of other applications.

[9]  Type the number of aln per read you want to allow (for Bowtie2), followed by
     [ENTER].

> For a better coverage, one can choose 3 alignments per read. Otherwise, 1 is recommended.

[10] Close the screen to let the analysis run :
     
      Ctrl + a, Ctrl + d
     
[11] Resume your screen to see if the job is completed :

      screen -r screenName

[12] If the job is completed, this message will appear :

      Experiment ExperimentName processed in X hours X minutes and X seconds !
      This experiment used X additional disk space on your device.
      Do you want to remove intermediate files ? [yes|no]

[13] Choose yes or no to remove or not intermediate files.

## PRECONDITIONS

- The input files must exist and be in FASTQ, SAM, BAM, SRA or FASTQ.GZ format.
- The reference genome file must be indexed.
- The device must have enough space to stock four times the size of each file.

## OUTPUT FILES

There will be a folder named yearMonthDay_hourMinSec. If the user choose to keep
intermediate files, this folder will contain four folder named fastFile,
trimFiles, alignFiles and sortedFiles. This last will contain the final files.
If the user choose to remove intermediate files, the final files will be in the
folder yearMonthDay_hourMinSec.

Each folder will contain these types of files :

    fastqFiles  -> filename.fastq.gz
                   filename.fastqc.zip

    trimFiles   -> filename_trim.fastq.gz

    alignFiles  -> filename_aln.bam

    sortedFiles -> filename_sorted.bam

Where filename.fastqc.zip is the FastQC quality analysis.

## HOW IT WORKS

This script will detect the input file format (FASTQ, BAM, SRA or FASTQ.GZ)
and will convert it into FASTQ.GZ format in the fastqFile directory (with SRA
Toolkit or Bedtools). Then, a FastQC quality analysis will be performed on these
files (with FastQC) and be stored in the same folder. From these analysis, the
encoding format and the overrepresented sequence (adapter) will be extracted. A
trimming will be done (with Trimmomatic) and the clean FASTQ.GZ files will be
stored in the trimFiles directory. Then, the alignment of these files is made
(with Bowtie2) and the output is stored in the alignFiles folder. These file are
then sorted (with Samtools). The user decides to keep or to delete intermediate
files at the end of the script execution.

