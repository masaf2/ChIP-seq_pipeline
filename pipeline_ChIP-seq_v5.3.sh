#!/bin/bash
# author: Marianne S. Felix
# marianne.sabourin-felix.1@ulaval.ca
# Version : 5.2
# 2015-06-12
# 2015-09-04
# 2016-02-24
# 2016-02-29
# 2016-03-02
#
# pipeline_ChIP-seq_v5.1.sh

########################################################
#                                                      #
#                                                      #
#   This script allows to process raw ChIP-seq data.   #
#                                                      #
#                                                      #
########################################################

################################
#                              #
#   Menu section               #
#                              #
################################

# Pipeline manual
pipelineManual="
MANUAL pipeline_ChIP-seq
2015-09-08

Marianne S. Felix
marianne.sabourin-felix.1@ulaval.ca
---------------------------------------

1. INTRODUCTION
2. WARNINGS
3. SOFTWARE DEPENDECIES
4. FILES REQUIREMENTS
5. HOW TO USE IT
6. PRECONDITIONS
7. OUTPUT FILES
8. HOW IT WORKS

==============
 INTRODUCTION
==============

This script process raw ChIP-seq data into aligned BAM files.

==========
 WARNINGS
==========

Caution, this script was tested only on Linux 14.04 LTS distribution and is
provided "as is", without warranty.

This script works only with SINGLE END files.

=======================
 SOFTWARE DEPENDENCIES
=======================

This script requires the following softwares :

 - SRA Toolkit
 - Bedtools
 - FastQC
 - Trimmomatic-0.33
 - Bowtie2
 - Samtools
 
 * Note that these packages are already installed on Zurich server.

====================
 FILES REQUIREMENTS
====================

The input file format can be either in FASTQ, SAM, BAM, SRA or FASTQ.GZ. One can
process as many file as wanted but one must consider the storage space on the
device (foresee four times the space of the file). Then, the reference genome
must be indexed. To do so, run the following command :

bowtie2-build -f genomeFile.fa genomeName
  or
bowtie2-buil -f genomeChr1.fa,genomeChr2.fa,genomeChr3.fa genomeName

  where genomeChr1.fa,...,genomeChr3.fa is the list of genome files.

===============
 HOW TO USE IT
===============

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

      If the analysis are made on a personal computer, 1 thread is recommended to
      ensure the smooth running of other applications.

[9]  Type the number of aln per read you want to allow (for Bowtie2), followed by
     [ENTER].

      For a better coverage, one can choose 3 alignments per read. Otherwise, 1
      is recommended.

[10] Close the screen to let the analysis run (it takes approximately 3 hours by
     file) :
     
      Ctrl + a, Ctrl + d
     
[11] Resume your screen to see if the job is completed :

      screen -r screenName

[12] If the job is completed, this message will appear :

      Experiment ExperimentName processed in X hours X minutes and X seconds !
      This experiment used X additional disk space on your device.
      Do you want to remove intermediate files ? [yes|no]

[13] Choose yes or no to remove or not intermediate files.

===============
 PRECONDITIONS
===============

- The input files must exist and be in FASTQ, SAM, BAM, SRA or FASTQ.GZ format.
- The reference genome file must be indexed.
- The device must have enough space to stock four times the size of each file.

==============
 OUTPUT FILES
==============

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

==============
 HOW IT WORKS
==============

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

"

# Custom display in shell
red=`tput setaf 1`
bold=`tput bold`
normal=`tput sgr0`
ERROR="$red[ERROR]$normal"

function transition {
    echo "$bold--------------------------------------------------------------------------------$normal"
}

mainMenu="$bold
*******************************************
*                                         *
*$normal   ChIP-seq pipeline version 5.3         $bold*
*   -----------------------------------   $bold*
*$normal   by Marianne S. Felix                  $bold*
*$normal                                         $bold*
*$normal   Please report any bug to :            $bold*
*$normal   marianne.sabourin-felix.1@ulaval.ca   $bold*
*                                         *
*******************************************$normal

$bold Main menu - Choose an option :
  1 .$normal Help/Manual
 $bold 2 .$normal Launch pipeline
 $bold 3 .$normal Quit
 
 $bold[TIP]$normal : One should preferably run its analysis into a \"screen\".
 
   Create a screen : screen -S screenName
   Close           : Ctrl + a, Ctrl + d
   List            : screen -ls
   Resume          : screen -r screenName
   Delete          : screen -S screenName -X quit
   
"

pipelineMenu="$bold
ChIP-seq pipeline version 5.3
--------------------------------------------------------------------------------$normal
This program require :
 - Input ChIP-seq files*
 - Indexed reference genome
 - The number of threads to use (for trimmomatic and Bowtie2)
 - The number of aln per read to allow (for Bowtie2)
* Only single end (SE) are accepted at the moment...

If the refence genome isn't indexed please do the following command :
   
    bowtie2-build -f genomeFile.fa genomeName
     or
    bowtie2-buil -f genomeChr1.fa,genomeChr2.fa,genomeChr3.fa genomeName
        where genomeChr1.fa,...,genomeChr3.fa is the list of genome files
$bold--------------------------------------------------------------------------------$normal
"

# Help
if [[ $1 == -h ]] || [[ $1 == --help ]]
then
    echo "$pipelineManual"
    exit
fi

printf "%s" "$mainMenu"

# Selection of user's choice
read -p "Type your option, followed by [ENTER] : " choice

# Validation of user's input
while [[ $choice <  1 || $choice > 3 ]] || [[ -z $choice ]]
do
    echo " $ERROR : Your choice must be 1, 2 or 3 !"
    read -p "Please type your option, followed by [ENTER] : " choice
done

# Switch to the case choosed by the user
case $choice in
    1) printf "%s" "$pipelineManual"; exit;;
    2) printf "%s" "$pipelineMenu";;
    3) echo "Exiting program... Goodbye !"; exit;;
esac


################################
#                              #
#   Selection of input files   #
#                              #
################################
    
# SE/PE

# The accepted file formats are the following
# The 'fastq.gz' format is not included in here because of the double extension
acceptedFormat=('fastq' 'fq' 'sam' 'bam' 'sra')

### Input of files ###
read -p "Are input files in a directory [d], or will be added manually file by file [f] ? " inputChoice
until [[ $inputChoice == @(d|D|f|F) ]] && [[ -n $inputChoice ]]
do
    echo " $ERROR : Your choice must be \"d\" for directory or \"f\" for file !"
    read -p "Are input files in a directory [d], or will be added manually (file by file) [f] ? " inputChoice
done

case $inputChoice in
    d|D)
        read -ep "Enter your input folder name, followed by [ENTER] : " inputFolder
        
        #TODO Find a more elegant way to do this...
        until [ -d $inputFolder ] && [[ `find $inputFolder/. -maxdepth 1 -type f -name "*.${acceptedFormat[0]}.gz" 2>/dev/null` ]] \
        || [[ `find $inputFolder/. -maxdepth 1 -type f -name "*.${acceptedFormat[0]}" 2>/dev/null` ]] \
        || [[ `find $inputFolder/. -maxdepth 1 -type f -name "*.${acceptedFormat[1]}" 2>/dev/null` ]] \
        || [[ `find $inputFolder/. -maxdepth 1 -type f -name "*.${acceptedFormat[2]}" 2>/dev/null` ]] \
        || [[ `find $inputFolder/. -maxdepth 1 -type f -name "*.${acceptedFormat[3]}" 2>/dev/null` ]] \
        || [[ `find $inputFolder/. -maxdepth 1 -type f -name "*.${acceptedFormat[4]}" 2>/dev/null` ]]
        do
            if [ -d $inputFolder ]
            then
                echo " $ERROR : The input folder must contain  fastq.gz, fastq, sam, bam or sra files !"
            else
                echo " $ERROR : Folder $inputFolder not found !"
            fi
            read -ep "Please enter your input folder name, followed by [ENTER] : " inputFolder
        done
        
        # Store the files in an array
        i=0
        for inputFile in $inputFolder/*
        do
            extension=`echo $inputFile | rev | cut -d '.' -f1,2 | rev`
            
            if [[ " ${acceptedFormat[@]} " =~ " ${inputFile##*.} " ]] || [[ $extension == fastq.gz ]]
            then
                files[$i]=`readlink -f $inputFile`
                i=$((i+1))
            fi
        done
        
        ;;
    f|F)
        read -p "Type the number of file(s) you want to process, followed by [ENTER] : " numFiles

        # Validation of user's input
        #while [[ -n ${numFiles//[1-9]/} ]] || [ -z $numFiles ]
        until [[ "$numFiles" =~ ^[1-9]+ ]]
        do
            echo " $ERROR : The number of file(s) must be an integer greater than 0 !"
            read -p "Please type the number of file(s) you want to process, followed by [ENTER] : " numFiles
        done

        # User's input (file must exists and have an accepted format)
        for (( fileNo=1; fileNo<=$numFiles; fileNo++ ))
        do
            read -ep "Enter your file #$fileNo, followed by [ENTER] : " fileInput
    
            # Allows to handle ../../path/to/file
            [ -f $fileInput -o -h $fileInput ] && inputFile=`readlink -f $fileInput` || inputFile=""
    
            until [[ " ${acceptedFormat[@]} " =~ " ${inputFile##*.} " ]]
            do  
                if [ -z $inputFile ]
                then
                    echo " $ERROR : File $fileInput not found !"
                else
                    # Allows to handle filenames with dots
                    extension=`echo $inputFile | rev | cut -d '.' -f1,2 | rev` 
                    if [[ $extension == fastq.gz ]]
                    then
                        break
                    else
                        echo " $ERROR : File format must be fastq.gz, fastq, sam, bam or sra !"
                    fi
                fi

                read -ep "Please enter your experiment file #$fileNo, followed by [ENTER] : " fileInput
        
                [ -f $fileInput -o -h $fileInput ] && inputFile=`readlink -f $fileInput` || inputFile=""
            done
    
            files[fileNo]=$inputFile
        done
        ;;
    *)
        echo " $red[ERROR104]$normal : An internal error occured, please report it to marianne.sabourin-felix.1@ulaval.ca"
        exit
esac


# Sigle end (SE) or Paired end (PE) sequencing
#read -p "Does the sequencing of your data is single end (SE) or paired end (PE) ? [SE|PE] : " end
#until [[ $end == SE ]] || [[ $end == PE ]]
#do
#    echo " $ERROR : Please answer SE or PE !"
#    read -p "Does the sequencing of your dataset is single end (SE) or paired end (PE) ? [SE|PE] : " end
#done
#
# TODO Handle PE option
#if [[ $end == PE ]]
#then
#    echo "$red[ERROR102]$normal : The PE option is not supported yet, please report it to marianne.sabourin-felix.1@ulaval.ca"
#    exit
#fi


### Input of indexed reference genome ###
read -ep "Enter path to the indexed reference genome basename \
(i.e. for Mm10.1.bt2 etc.: /path/to/index/Mm10), followed by [ENTER] : " refGenInput
# Remove trailing point
refGen=${refGenInput%.}

# Validation of user's input (must exists)
until [ -f $refGen.1.bt2 ] && [ -f $refGen.2.bt2 ] && \
      [ -f $refGen.3.bt2 ] && [ -f $refGen.4.bt2 ] && \
      [ -f $refGen.rev.1.bt2 ] && [ -f $refGen.rev.2.bt2 ] && [ -n $refGen ]
do
    if [ -z $refGen ] || [ -n "$refGen"* ]
    then
        echo " $ERROR : $refGen not found !"
    elif [ -d $refGen ]
    then
        echo " $ERROR : $refGen is a directory !"
    else
        echo " $ERROR : Some index files are missing in directory $refGen..."
        echo "Required files are : name.1.bt2, name.2.bt2, name.3.bt2, name.4.bt2, name.rev.1.bt2 and name.rev.2.bt2 "
    fi
    read -ep "Please enter path to the indexed reference genome basename, followed by [ENTER] : " refGenInput
    refGen=${refGenInput%.}
done

refGenome=`readlink -f $refGen`


# Number of thread(s)
read -p "Type the number of thread(s) you want to use (for trimmomatic and Bowtie2), followed by [ENTER] : " threads

# Validation of user's input
#while [[ -n ${threads//[1-9]/} ]] || [ -z $threads ]
until [[ "$threads" =~ ^[1-9]+ ]]
do
    echo " $ERROR : The number of thread(s) must be an integer greater than 0 !"
    read -p "Type the number of thread(s) you want to use (for trimmomatic and Bowtie2), followed by [ENTER] : " threads
done


# LEADING (must be between 0 and 41)
read -p "Type the minimum score you want to use for trimmomatic LEADING option, followed by [ENTER] : " leading
while (( $leading < 0 )) || (( $leading > 41 )) || [ -z $leading ] || [[ ${leading:0:1} == - ]]
do
    echo " $ERROR : The minimum score must be an integer between 0 and 41 !"
    read -p "Type the minimum score you want to use for trimmomatic LEADING option, followed by [ENTER] : " leading
done

# TRAILING (must be between 0 and 41)
read -p "Type the minimum score you want to use for trimmomatic TRAILING option, followed by [ENTER] : " trailing
while (( $trailing < 0 )) || (( $trailing > 41 )) || [ -z $trailing ] || [[ ${trailing:0:1} == - ]]
do
    echo " $ERROR : The minimum score must be an integer between 0 and 41 !"
    read -p "Type the minimum score you want to use for trimmomatic TRAILING option, followed by [ENTER] : " trailing
done

# MINLEN (must be between 0 and 100)
read -p "Type the minimum length you want to use for trimmomatic MINLEN option, followed by [ENTER] : " minlen
while (( $minlen < 0 )) || (( $minlen > 100 )) || [ -z $minlen ] || [[ ${minlen:0:1} == - ]]
do
    echo " $ERROR : The minimum length must be an integer between 0 and 100 !"
    read -p "Type the minimum length you want to use for trimmomatic MINLEN option, followed by [ENTER] : " minlen
done

# Adapters
read -p "Do you want to remove adapters from dataset ? [yes|no] : " adaptChoice
until [[ $adaptChoice == yes ]] || [[ $adaptChoice == no ]]
do
    echo " $ERROR : Please answer yes or no !"
    read -p "Do you want to remove adapters from dataset ? [yes|no] : " adaptChoice
done

# Adapter file
# TODO Accept *.fasta format
#/home/bickj/software/Trimmomatic-0.33/adapters/TruSeq3-SE.fa
if [[ $adaptChoice == yes ]]
then
    read -ep "Type the path to the adapter file ex: /home/App/Trimmomatic-0.33/adapters/TruSeq3-SE.fa, followed by [ENTER] : " adapterFile
    until [ -f $adapterFile -o -h $adapterFile ] && [[ ${adapterFile##*.} == fa ]]
    do
        if [ -f $adapterFile -o -h $adapterFile -o -z $adapterFile ]
        then
            echo " $ERROR : Adapter file must be in *.fa format !"
        else
            echo " $ERROR : Adapter file $adapterFile not found !"
        fi
    
        read -ep "Type the path to the adapter file ex: /home/App/Trimmomatic-0.33/adapters/TruSeq3-SE.fa, followed by [ENTER] : " adapterFile
    done
    
    adaptFile=`readlink -f $adapterFile`
    
    # Set the ILLUMINACLIP default settings (if the user say no to clipChoice)
    seedMismatch=2
    palindromeClipThreshold=30
    simpleClipThreshold=10
    
    read -p "Do you want to change the ILLUMINACLIP settings ? (Default : ILLUMINACLIP:adapterFile:2:30:10) [yes|no] : " clipChoice
    until [[ $clipChoice == yes ]] || [[ $clipChoice == no ]]
    do
        echo " $ERROR : Please answer yes or no !"
        read -p "Do you want to change the ILLUMINACLIP settings ? (Default : ILLUMINACLIP:adaptFile:2:30:10) [yes|no] : " clipChoice
    done
    
    # TODO Change the range of possible answer...
    if [[ $clipChoice == yes ]]
    then
        read -p "Type the maximal seed mismatch you want to allow for trimmomatic ILLUMINACLIP option (Default=2), followed by [ENTER] : " seedMismatch
        until [[ "$seedMismatch" =~ ^[0-9]+ ]]
        do
            echo " $ERROR : The maximal seed mismatch must be an integer equal or greater than 0 !"
            read -p "Type the maximal seed mismatch you want to allow for trimmomatic ILLUMINACLIP option (Default=2), followed by [ENTER] : " seedMismatch
        done
        
        read -p "Type the minimum score for palindrome match you want to allow for trimmomatic ILLUMINACLIP option (Defaut=30), followed by [ENTER] : " palindromeClipThreshold
        until [[ "$palindromeClipThreshold" =~ ^[0-9]+ ]]
        do
            echo " $ERROR : The maximal seed mismatch must be an integer equal or greater than 0 !"
            read -p "Type the minimum score for palindrome match you want to allow for trimmomatic ILLUMINACLIP option (Defaut=30), followed by [ENTER] : " palindromeClipThreshold
        done
        
        read -p "Type the minimum score for simple match you want to allow for trimmomatic ILLUMINACLIP option (Defaut=10), followed by [ENTER] : " simpleClipThreshold
        until [[ "$simpleClipThreshold" =~ ^[0-9]+ ]]
        do
            echo " $ERROR : The maximal seed mismatch must be an integer equal or greater than 0 !"
            read -p "Type the minimum score for simple match you want to allow for trimmomatic ILLUMINACLIP option (Defaut=10), followed by [ENTER] : " simpleClipThreshold
        done
    fi
        
fi

# Number of alignment per reads 
read -p "Type the number of alignment with different k value (aln per read) you want to do, followed by [ENTER] : " numAln
until [[ "$numAln" =~ ^[1-9]+ ]]
do
    echo " $ERROR : The number of alignment must be an integer greater than 0 !"
    read -p "Type the number of alignment with different k value (aln per read) you want to do, followed by [ENTER] : " numAln
done

for (( alnNo=1; alnNo<=$numAln; alnNo++ ))
do
    read -p "Enter your k value (aln per read) #$alnNo, followed by [ENTER] : " kValue
    until [[ "$kValue" =~ ^[1-9]+ ]]
    do
        echo " $ERROR : The k value must be an integer greater than 0 !"
        read -p "Enter your k value (aln per read) #$alnNo, followed by [ENTER] : " kValue
    done
        
    kValues[$alnNo]=$kValue
done

transition

#TODO Ask the user which steps of the analysis he/she wants to perform...

StartTime=$(date +%s)

### Creation of output folders ###

Date=$(date +%Y-%m-%d)
Hour=$(date +%H:%M:%S)

experiment=$(date +%Y%m%d_%H%M%S)
mkdir $experiment
cd $experiment

### Creating a log file ###
log=$experiment.log
touch $log

function transitionLog {
    echo "--------------------------------------------------------------------------------" >> $log
}

echo "================" >> $log
echo "==  LOG FILE  ==" >> $log
echo "================" >> $log
echo "" >> $log

echo "Creating new experiment directory (yearMonthDay_hourMinSec) : $experiment..." | tee -a $log
transition
transitionLog

################################
#                              #
#   Settings summary file      #
#                              #
################################

### Creation of a settings summary file ###

echo "Creating a settings summary file..." | tee -a $log

summary=settingsSummary-$experiment.txt
touch $summary
echo "==============================" >> $summary
echo "== PROCESSING CHIP-SEQ DATA ==" >> $summary
echo "==============================" >> $summary
echo "" >> $summary
echo "ChIP-Seq pipeline version 5.2" >> $summary
echo "Job started on $Date at $Hour by $USER." >> $summary
echo "" >> $summary

echo "-------------" >> $summary
echo " Input files " >> $summary
echo "-------------" >> $summary
echo "" >> $summary

for file in ${files[@]}
do
    echo "$file" >> $summary
done
echo "" >> $summary

echo "---------------------------" >> $summary
echo " Reference genome basename " >> $summary
echo "---------------------------" >> $summary
echo "" >> $summary

echo "$refGenome" >> $summary
echo "" >> $summary

echo "------------------" >> $summary
echo " Input parameters " >> $summary
echo "------------------" >> $summary
echo "" >> $summary

echo "Number of threads (for Trimmomatic and Bowtie2) : $threads" >> $summary
echo "" >> $summary

echo "LEADING option (for Trimmomatic) : $leading" >> $summary
echo "TRAILING option (for Trimmomatic) : $trailing" >> $summary
echo "MINLEN option (for Trimmomatic) : $minlen" >> $summary
echo "" >> $summary

if [[ $adaptChoice == yes ]]
then
    echo "Adapter file : $adaptFile" >> $summary
    echo "ILLUMINACLIP SeedMismatch option (for Trimmomatic) : $seedMismatch" >> $summary
    echo "ILLUMINACLIP PalindromeClipThreshold option (for Trimmomatic) : $palindromeClipThreshold" >> $summary
    echo "ILLUMINACLIP SimpleClipThreshold option (for Trimmomatic) : $simpleClipThreshold" >> $summary
    echo "" >> $summary
fi

echo -n "Number of alignment per read (k value) (for Bowtie2) : " >> $summary
i=0
for k in ${kValues[@]}
do
    [[ $i > 0 ]] && echo -n ", " >> $summary
    echo -n $k >> $summary
    i=$((i+1))
done
echo "" >> $summary

echo "File settingsSummary.txt created !" | tee -a $log
transition
transitionLog

################################
#                              #
#   ChIP-seq data processing   #
#                              #
################################

### Creating QualityCheck and FinalFiles folder ###
mkdir QualityCheck FinalFiles

### Processing one file at a time ! ###
for file in ${files[@]}
do
    echo "$bold PROCESSING FILE :$normal" `basename $file`
    echo " PROCESSING FILE :" `basename $file` >> $log
    transition
    transitionLog
    
    # Attribution of fastq file name
    if [[ "${file##*.}" == gz ]]
    then
        fastqFile=$file
        echo "File" `basename $file` "already in fastq.gz format." | tee -a $log
        echo "Skipping data conversion step !" | tee -a $log
    else
        fastqFile=`basename "${file%.*}"`.fastq.gz
        echo "Converting file" `basename $file` "to fastq.gz format..." | tee -a $log
    fi
    
    ### 1 - Data conversion ###
    
    case "${file##*.}" in

        gz)
            # Corresponding to fastq.gz format (validated earlier)
            # File already in the right format
            continue
            ;;
            
        fastq|fq)
            #gzip -c $file > $experiment/$fastqFile
            gzip -c $file > $fastqFile
            ;;
            
        sra)
            #fastq-dump --gzip $file -O $experiment
            fastq-dump --gzip $file
            ;;
            
        bam)
            outputFastq=`basename "${file%.*}"`.fastq
            #cd $experiment
            bedtools bamtofastq -i $file -fq $outputFastq
            gzip $outputFastq
            #cd ../../
            ;;
            
        sam)
            #TODO DOESN'T WORK since sam files contains the reverse complement of reverse reads...
            #outputFastq=`basename "${file%.*}"`.fastq.gz
            #egrep -v '^@' $file | awk '{printf "@%s\n%s\n+%s\n%s\n", $1, $10, $1, $11}' \
            #| gzip -c > $fastqFolder/$outputFastq
            echo " $red[ERROR101]$normal : Sam format not supported yet, please report it to marianne.sabourin-felix.1@ulaval.ca"
            echo " [ERROR101] : Sam format not supported yet, please report it to marianne.sabourin-felix.1@ulaval.ca" >> $log
            exit
            ;;
            
        *)
            echo " $red[ERROR102]$normal : An internal error occured, please report it to marianne.sabourin-felix.1@ulaval.ca"
            echo " [ERROR102] : An internal error occured, please report it to marianne.sabourin-felix.1@ulaval.ca" >> $log
            exit
            ;;
    esac
    
    [[ "${file##*.}" != gz ]] && echo "Fastq.gz file $fastqFile created !" | tee -a $log
    
    transition
    transitionLog
    
    
    ### 2 - Quality control ###
    
    echo "Running FastQC quality analysis for file" `basename $fastqFile`"..." | tee -a $log
    fastqc $fastqFile -q -O QualityCheck &>> $log
    echo "FastQC quality analysis done for file" `basename $fastqFile`" !" | tee -a $log
    
    # Remove unnecessary files
    rm QualityCheck/`basename $fastqFile .fastq.gz`"_fastqc.zip"
    
    # Detect encoding format
    qltyFolder=`basename $fastqFile .fastq.gz`"_fastqc"
    encoding=`grep -w 'Encoding' QualityCheck/$qltyFolder/fastqc_data.txt`
    
    if [[ $encoding == *Illumina*1.5* ]]
    then
        phred="phred64"
    elif  [[ $encoding == *Sanger*Illumina*1.9* ]]
    then
        phred="phred33"
    else
        echo " $red[ERROR102]$normal : Phred encoding format not supported yet, please report to marianne.sabourin-felix.1@ulaval.ca"
        echo " [ERROR102] : Phred encoding format not supported yet, please report to marianne.sabourin-felix.1@ulaval.ca" >> $log
        exit
    fi
    
    echo "P${phred:1} encoding detected for" `basename $fastqFile` "!" | tee -a $log
    
    transition
    transitionLog
    
    
    ### 3 - Data trimming ###
    
    echo "Running Trimmomatic trimming for file " `basename $fastqFile`"..." | tee -a $log
    
    trimFile=`basename $fastqFile .fastq.gz`_trim.fastq.gz
    
    # Find Trimmomatic path
    pathTrimmomatic=`locate Trimmomatic-0.33/trimmomatic-0.33.jar`
    
    if [[ $adaptChoice == yes ]]
    then
        java -jar $pathTrimmomatic SE -threads $threads -$phred $fastqFile \
        $trimFile LEADING:$leading TRAILING:$trailing MINLEN:$minlen \
        ILLUMINACLIP:$adaptFile:$seedMismatch:$palindromeClipThreshold:$simpleClipThreshold \
        MINLEN:$minlen &>> $log
        
    else
        java -jar $pathTrimmomatic SE -threads $threads -$phred $fastqFile \
        $trimFile LEADING:$leading TRAILING:$trailing MINLEN:$minlen &>> $log
    fi
    
    echo "Trimmed file $trimFile created !" | tee -a $log
    
    # Remove *.fastq.gz file if not original
    [[ "${file##*.}" != gz ]] && rm $fastqFile
    
    echo "Running FastQC quality analysis for file $trimFile..." | tee -a $log
    fastqc $trimFile -q -O QualityCheck &>> $log
    echo "FastQC quality analysis done for file $trimFile !" | tee -a $log
    
    # Remove unnecessary files
    rm QualityCheck/`basename $trimFile .fastq.gz`"_fastqc.zip"
    
    transition
    transitionLog
    
    
    ### 4 - Alignment ###
    
    for k in ${kValues[@]}
    do
        echo "Running Bowtie alignment (k$k) for file $trimFile..." | tee -a $log
    
        alnFile=`basename $trimFile _trim.fastq.gz`-k$k"_aln.bam"
    
        bowtie2 -p $threads -k $k -x $refGenome -U $trimFile 2>> $log \
        | samtools view -F 4 -bS - > $alnFile
    
        echo "Alignment file $alnFile created !" | tee -a $log
        
        transition
        transitionLog
    done
    
    # Remove trimmed file (no longer needed)
    rm $trimFile


    ### 5 - Sorting ###
    
    for alnFile in *_aln.bam
    do
        echo "Sorting file $alnFile by chromosomal coordinates..." | tee -a $log
    
        sortedFile=`basename $alnFile _aln.bam`_sorted
    
        samtools sort $alnFile FinalFiles/$sortedFile &>> $log
    
        echo "Sorted file $sortedFile.bam created !" | tee -a $log
    
        # Remove alignment file (no longer needed)
        rm $alnFile
        
        transition
        transitionLog
        
        
        ### 6 - Indexing ###
        
        echo "Creating index for file $sortedFile.bam..." | tee -a $log
        samtools index FinalFiles/$sortedFile.bam &>> $log
        echo "Index file $sortedFile.bam.bai created !" | tee -a $log
        
    done
    
    transition
    transitionLog

done

# Separe files according to their k value
if [[ $numAln > 1 ]]
then
    for k in ${kValues[@]}
    do
        mkdir FinalFiles/k$k
        
        mv FinalFiles/*-k$k"_"* FinalFiles/k$k/
    done
fi

cd ../


EndTime=$(date +%s)
ElapsedTime=$(($EndTime - $StartTime))

space=`du -sh $experiment | cut -f 1`

echo "Experiment $experiment used $space of additional disk space on your device" | tee -a $experiment/$log

echo "and was processed in $(($ElapsedTime / 3600 )) hours $((($ElapsedTime % 3600) / 60)) \
minutes $(($ElapsedTime % 60)) seconds !" | tee -a $experiment/$log

transition
echo "--------------------------------------------------------------------------------" >> $experiment/$log

echo "Final files are in folder $experiment/FinalFiles ! :)" | tee -a $experiment/$log


