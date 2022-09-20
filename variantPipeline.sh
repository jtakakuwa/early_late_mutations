#!/bin/bash 

### Organize and rename files 

### Files had different naming structures, so a script was used to change all files to the same pattern depending on sample name 

### Make directory to store fastqFiles 
mkdir fastqFiles 

### Loop through all sample directories
### Move all fastq files to the fastq directory 
for d in */ ; do

    cd "$d"
    find *.fastq -exec mv -t /home/jtakakuwa/vitisProj/radio_samples/fastqFiles {} + 
    cd ..   

done 

cd fastqFiles 

### Script to rename fastq files according to sample organism, sample name, and R1 and R2 
for d in * ; do
    a="$d" 
    c=`expr index "$d" _`
    b=${a:0:c-1}
    h="R1"
    i="R2"
    r="rradio_"
    s="_"
    t=".fastq"
    if [[ "$a" == *"$h"* ]];
    then 
        mv "$d" "$r$b$s$h$t"
    else
        mv "$d" "$r$b$s$i$t"
    fi 

done 


### Run BWA 

### Index the reference genome
### Note that you only need to do this once
bwa index -p rradio_copy.fa /home/jtakakuwa/vitisProj/IndexRef/rradio_copy.fa

### Loop through fastq files 
for d in *_R1.fastq ; do

    ### Isolate and store sample names in a separate variable  
    a="$d"
    c="${#a}"
    b=${a:7:c-16}

    ### Use variable to create strings that reference R1 and R2 fastq files  
    d=rradio_"$b"_R1.fastq 
    e=rradio_"$b"_R2.fastq

    ### Run BWA and output SAM file 
    bwa mem -t 16 /home/jtakakuwa/vitisProj/IndexRef/rradio_copy.fa "$d" "$e
" > "$b"_2022.sam

done 

### Make new directory to store SAM files 
mkdir radioSamFiles 

### Move all SAM files to the new directory 
for d in *.sam; do 

    mv "$d" ./radioSamFiles

done  


### Preparation for BCFtools variant calling 

### Create an index for the reference file using samtools 
samtools faidx /home/jtakakuwa/vitisProj/IndexRef/rradio_copy.fa

### Change to the directory with SAM files 
cd /home/jtakakuwa/vitisProj/radio_samples/fastqFiles/radioSamFiles

### Loop through SAM files 
for d in *.sam; do

    ### Isolate and store sample names in a separate variable
    a="$d" 
    b=${a::-4}

    ### Converts SAM file to BAM file 
    samtools view -b -t /home/jtakakuwa/vitisProj/IndexRef/rradio_copy.fa.fa
i -o "$b".bam "$b".sam  

    ### Sorts reads in the BAM file 
    samtools sort -o "$b"_sort.bam -O BAM "$b".bam 

    ### Produces .bai index for BAM file 
    samtools index "$b"_sort.bam 

    ### Create mpileup files for each sample 
    bcftools mpileup -f /home/jtakakuwa/vitisProj/IndexRef/rradio_copy.fa "$
b"_sort.bam -o "$b".mpileup

    ### Use mpileups to create VCF files 
    bcftools call -c -v --ploidy 1 "$b".mpileup -o "$b"_calls.vcf

done 
