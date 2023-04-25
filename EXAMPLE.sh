#!/bin/bash
#SBATCH --partition=defq      # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=10      #   
#SBATCH --mem-per-cpu=2000     # in megabytes, unless unit explicitly stated
#SBATCH --error=%J.err         # redirect stderr to this file
#SBATCH --output=%J.out        # redirect stdout to this file
#SBATCH --mail-user=WhiteN8@Cardiff.ac.uk  # email address used for event notification
#SBATCH --mail-type=end                                   # email on job end
##SBATCH --mail-type=fail                                  # email on job failure

# SCRIPT TO MAP ALL 92 RAW, SINGLE-END FASTQs TO REFERENCE BD JEL423 GENOME #
# execute from /mnt/scratch/c1312466/Fluidigm/Mapping/

# load modules
module load bwa/v0.7.17
module load samtools/1.10

# Set up out file paths
outBWA=/mnt/scratch/c1312466/Fluidigm/Mapping/FG.RR

#Index the reference genome (choose short or full)
bwa index /mnt/scratch/c1312466/Fluidigm/Mapping/Refs/JEL423.fasta

#Align using mem algorithm and specifying read groups to be added, output is .sam file
cd /mnt/scratch/c1312466/Fluidigm/Mapping/FLASH_OUT/
for dir in *; do
	cd $dir;
	bwa mem -t ${SLURM_CPUS_PER_TASK} -R "@RG\tID:${dir}\tSM:${dir}" /mnt/scratch/c1312466/Fluidigm/Mapping/Refs/JEL423.fasta out.extendedFrags.fastq > ${outBWA}/"$dir".sam

	#use samtools to change .sam to .bam
	samtools view -@ ${SLURM_CPUS_PER_TASK} -bS ${outBWA}/"$dir".sam > ${outBWA}/"$dir".bam

	#sort alignments by leftmost coordinates and output to new sorted file, 
	#@ specifies number of cpus to use - referencing the sbatch command above
	samtools sort -@ ${SLURM_CPUS_PER_TASK} ${outBWA}/"$dir".bam > ${outBWA}/"$dir"_sort.bam
 cd ../
done 
 
 #filter the sorted bam files, omitting alignments with map qual below 20 and output in bam format with headings
 #pipe to view them omitting bits set in 0x400 - PCR duplicates
 #send to output file that is sorted and filtered
cd $outBWA
for f in *_sort.bam; do
ID=${f%_*.bam}
	samtools view -@ ${SLURM_CPUS_PER_TASK} -q 20 -bh ${f} | samtools view -@ ${SLURM_CPUS_PER_TASK} -bh -F 0x400 > ${outBWA}/"$ID"_filter.bam
done 
