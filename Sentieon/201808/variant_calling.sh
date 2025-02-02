#!/bin/bash
#PBS -l select=1:ncpus=40
#PBS -q nhri192G
#PBS -P MST108173
#PBS -W group_list=MST108173
#PBS -N SAMPLE_NAME 
#PBS -M jacobhsu@connect.hku.hk
#PBS -m a
#PBS -j oe
#### Date: 20210328
# This is the identical pipeline for TWB 1496 cohort and seven GIAB samples

#/project/GP1/u3710062/AI_SHARE/GATK/Inputs/20200528_GIAB/SAMPLE_NAME_plus.R1.fastq

JOBDIR="/project/GP1/u3710062/AI_SHARE/GATK/Outputs/20200528_GIAB"

SampleName=SAMPLE_NAME

cd $JOBDIR

set -euo pipefail

printf "#############################################################################\n"
printf "###                  Work started:   $(date +%Y-%m-%d:%H:%M:%S)                  ###\n"
printf "#############################################################################\n"


# *******************************************
# Script to perform DNA seq variant calling
# using a single sample with fastq files
# named 1.fastq.gz and 2.fastq.gz
# *******************************************

# Update with the fullpath location of your sample fastq

fastq_folder="//project/GP1/u3710062/AI_SHARE/GATK/Inputs/20200528_GIAB/"
fastq_1="${fastq_folder}/${SampleName}*.R1.fastq" #NGS1_20170305A.R1.fastq.gz
fastq_2="${fastq_folder}/${SampleName}*.R2.fastq"  #If using Illumina paired data
sample="SM_"${SampleName}
group="GP_"${SampleName}
platform="ILLUMINA"


# Update with the location of the reference data files
ref_dir="/project/GP1/u3710062/AI_SHARE/reference/GATK_bundle/2.8/hg19"

fasta="${ref_dir}/ucsc.hg19.fasta"
dbsnp="${ref_dir}/dbsnp_138.hg19.vcf"
known_Mills_indels="${ref_dir}/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf"
known_1000G_indels="${ref_dir}/1000G_phase1.indels.hg19.sites.vcf"

# Determine whether Variant Quality Score Recalibration will be run
# VQSR should only be run when there are sufficient variants called
run_vqsr="yes"

# Update with the location of the resource files for VQSR
vqsr_Mill="${ref_dir}/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf"
vqsr_1000G_omni="${ref_dir}/1000G_omni2.5.hg19.sites.vcf"
vqsr_hapmap="${ref_dir}/hapmap_3.3.hg19.sites.vcf"
vqsr_1000G_phase1="${ref_dir}/1000G_phase1.snps.high_confidence.hg19.sites.vcf"
vqsr_1000G_phase1_indel="${ref_dir}/1000G_phase1.indels.hg19.sites.vcf"
vqsr_dbsnp="${ref_dir}/dbsnp_138.hg19.vcf"

# Update with the location of the Sentieon software package and license file
export SENTIEON_LICENSE=140.110.16.119:8990
release_dir="/project/GP1/u3710062/AI_SHARE/software/Sentieon/sentieon-genomics-201808"

# Other settings
nt=40 #number of threads to use in computation
workdir=${JOBDIR}/${SampleName} #Determine where the output files will be stored

# ******************************************
# 0. Setup
# ******************************************
mkdir -p $workdir
logfile=$workdir/run.log
set -x
exec 3<&1 4<&2
exec >$logfile 2>&1

cd $workdir


# ******************************************
# 1. Mapping reads with BWA-MEM, sorting
# ******************************************
#The results of this call are dependent on the number of threads used. To have number of threads independent results, add chunk size option -K 10000000


#if [ ! -d "${ref_dir}/ucsc.hg19.fasta.bwt" ]; then
#$release_dir/bin/bwa index $fasta
#fi

($release_dir/bin/bwa mem -M -R "@RG\tID:$group\tSM:$sample\tPL:$platform" -t $nt -K 10000000 $fasta $fastq_1 $fastq_2 || echo -n 'error' ) | $release_dir/bin/sentieon util sort -r $fasta -o ${SampleName}.sorted.bam -t $nt --sam2bam -i -


# ******************************************
# 2. Metrics
# ******************************************
#$release_dir/bin/sentieon driver -r $fasta -t $nt -i sorted.bam --algo MeanQualityByCycle mq_metrics.txt --algo QualDistribution qd_metrics.txt --algo GCBias --summary gc_summary.txt gc_metrics.txt --algo AlignmentStat --adapter_seq '' aln_metrics.txt --algo InsertSizeMetricAlgo is_metrics.txt
#$release_dir/bin/sentieon plot metrics -o metrics-report.pdf gc=gc_metrics.txt qd=qd_metrics.txt mq=mq_metrics.txt isize=is_metrics.txt


# ******************************************
# 3. Remove Duplicate Reads
# ******************************************
$release_dir/bin/sentieon driver  -t $nt -i ${SampleName}.sorted.bam --algo LocusCollector --fun score_info ${SampleName}.score.txt
$release_dir/bin/sentieon driver  -t $nt -i ${SampleName}.sorted.bam --algo Dedup --rmdup --score_info ${SampleName}.score.txt --metrics ${SampleName}.dedup_metrics.txt ${SampleName}.deduped.bam


# ******************************************
# 4. Indel realigner
# ******************************************
$release_dir/bin/sentieon driver -r $fasta  -t $nt -i ${SampleName}.deduped.bam --algo Realigner -k $known_Mills_indels -k $known_1000G_indels ${SampleName}.realigned.bam


# ******************************************
# 5. Base recalibration
# ******************************************
$release_dir/bin/sentieon driver -r $fasta -t $nt -i ${SampleName}.realigned.bam --algo QualCal -k $dbsnp -k $known_Mills_indels -k $known_1000G_indels ${SampleName}.recal_data.table
#$release_dir/bin/sentieon driver -r $fasta -t $nt -i realigned.bam -q recal_data.table --algo QualCal -k $dbsnp -k $known_Mills_indels -k $known_1000G_indels recal_data.table.post
#$release_dir/bin/sentieon driver -t $nt --algo QualCal --plot --before recal_data.table --after recal_data.table.post recal.csv
#$release_dir/bin/sentieon plot bqsr -o recal_plots.pdf recal.csv


# ******************************************
# 6a. UG Variant caller
# ******************************************
#$release_dir/bin/sentieon driver -r $fasta -t $nt -i realigned.bam -q recal_data.table --algo Genotyper -d $dbsnp --var_type BOTH --emit_conf=10 --call_conf=30 output-ug.vcf.gz


# ******************************************
# 6b. HC Variant caller
# ******************************************
$release_dir/bin/sentieon driver -r $fasta -t $nt -i ${SampleName}.realigned.bam -q ${SampleName}.recal_data.table --algo Haplotyper -d $dbsnp --emit_conf=10 --call_conf=30 ${SampleName}.output-hc.vcf.gz

# gvcf
$release_dir/bin/sentieon driver -r $fasta -t $nt -i ${SampleName}.realigned.bam -q ${SampleName}.recal_data.table --algo Haplotyper -d $dbsnp --emit_mode gvcf ${SampleName}.output-hc.g.vcf.gz

# ******************************************
# 5b. ReadWriter to output recalibrated bam
# This stage is optional as variant callers
# can perform the recalibration on the fly
# using the before recalibration bam plus
# the recalibration table
# ******************************************
$release_dir/bin/sentieon driver -r $fasta -t $nt -i ${SampleName}.realigned.bam -q ${SampleName}.recal_data.table --algo ReadWriter ${SampleName}.recaled.bam


# ******************************************
# 7a. Somatic and Structural variant calling
# ******************************************
# $release_dir/bin/sentieon driver -r $fasta  -t $nt -i tn_corealigned.bam --algo TNscope --tumor_sample $tumor_sample --normal_sample $normal_sample --dbsnp $dbsnp output_tnscope.vcf.gz
#$release_dir/bin/sentieon driver -r $fasta  -t $nt -i ${SampleName}.realigned.bam -q ${SampleName}.recal_data.table --algo TNscope --tumor_sample $sample  --dbsnp $dbsnp ${SampleName}.output_tnscope.vcf.gz


# ******************************************
# 7b. Variant Recalibration
# ******************************************
if [ "$run_vqsr" = "yes" ]; then
  #for SNP
  #create the resource argument
  resource_text="--resource $vqsr_1000G_phase1 --resource_param 1000G,known=false,training=true,truth=false,prior=10.0 "
  resource_text="$resource_text --resource $vqsr_1000G_omni --resource_param omni,known=false,training=true,truth=true,prior=12.0 "
  resource_text="$resource_text --resource $vqsr_dbsnp --resource_param dbsnp,known=true,training=false,truth=false,prior=2.0 "
  resource_text="$resource_text --resource $vqsr_hapmap --resource_param hapmap,known=false,training=true,truth=true,prior=15.0"

  #create the annotation argument
  annotation_array="QD MQ MQRankSum ReadPosRankSum FS"

  #Initial annotate_text variable
  annotate_text=""
  for annotation in $annotation_array; do
    annotate_text="$annotate_text --annotation $annotation"
  done

  #Run the VQSR
  tranches="--tranche 100.0 --tranche 99.9 --tranche 99.0 --tranche 98.0 --tranche 97.0 --tranche 96.0 --tranche 95.0 --tranche 94.0 --tranche 93.0 --tranche 92.0 --tranche 91.0 --tranche 90.0"
  $release_dir/bin/sentieon driver -r $fasta -t $nt --algo VarCal -v ${SampleName}.output-hc.vcf.gz $resource_text $annotate_text --var_type SNP --plot_file ${SampleName}.vqsr_SNP.hc.plot_file.txt --max_gaussians 8 --srand 47382911 --tranches_file ${SampleName}.vqsr_SNP.hc.tranches ${SampleName}.vqsr_SNP.hc.recal $tranches

  #apply the VQSR
  $release_dir/bin/sentieon driver -r $fasta -t $nt --algo ApplyVarCal -v ${SampleName}.output-hc.vcf.gz --var_type SNP --recal ${SampleName}.vqsr_SNP.hc.recal --tranches_file ${SampleName}.vqsr_SNP.hc.tranches --sensitivity 99.5 ${SampleName}.vqsr_SNP.hc.recaled.vcf.gz

  #plot the report
  $release_dir/bin/sentieon plot vqsr -o ${SampleName}.vqsr_SNP.VQSR.pdf ${SampleName}.vqsr_SNP.hc.plot_file.txt

  #for indels after SNPs
  #create the resource argument
  resource_text="--resource $vqsr_1000G_phase1_indel --resource_param 1000G,known=false,training=true,truth=false,prior=10.0 "
  resource_text="$resource_text --resource $vqsr_Mill --resource_param Mills,known=false,training=true,truth=true,prior=12.0 "
  resource_text="$resource_text --resource $vqsr_dbsnp --resource_param dbsnp,known=true,training=false,truth=false,prior=2.0 "

  #create the annotation argument
  annotation_array="QD MQ ReadPosRankSum FS"
  annotate_text=""
  for annotation in $annotation_array; do
    annotate_text="$annotate_text --annotation $annotation"
  done

  #Run the VQSR
  tranches="--tranche 100.0 --tranche 99.9 --tranche 99.0 --tranche 98.0 --tranche 97.0 --tranche 96.0 --tranche 95.0 --tranche 94.0 --tranche 93.0 --tranche 92.0 --tranche 91.0 --tranche 90.0"
  $release_dir/bin/sentieon driver -r $fasta -t $nt --algo VarCal -v ${SampleName}.vqsr_SNP.hc.recaled.vcf.gz $resource_text $annotate_text --var_type INDEL --plot_file ${SampleName}.vqsr_SNP_INDEL.hc.plot_file.txt --max_gaussians 4 --srand 47382911 --tranches_file ${SampleName}.vqsr_SNP_INDEL.hc.tranches ${SampleName}.vqsr_SNP_INDEL.hc.recal $tranches

  #apply the VQSR
  $release_dir/bin/sentieon driver -r $fasta -t $nt --algo ApplyVarCal -v ${SampleName}.vqsr_SNP.hc.recaled.vcf.gz --var_type INDEL --recal ${SampleName}.vqsr_SNP_INDEL.hc.recal --tranches_file ${SampleName}.vqsr_SNP_INDEL.hc.tranches --sensitivity 99.5 ${SampleName}.vqsr_SNP_INDEL.hc.recaled.vcf.gz

  #plot the report
  $release_dir/bin/sentieon plot vqsr -o ${SampleName}.vqsr_SNP_INDEL.VQSR.pdf ${SampleName}.vqsr_SNP_INDEL.hc.plot_file.txt
fi


if [[ $? -eq 0 ]]; then
	ls ${SampleName}.deduped.bam ${SampleName}.realigned.bam ${SampleName}.recaled.bam
	rm ${SampleName}.deduped.bam ${SampleName}.realigned.bam ${SampleName}.recaled.bam
fi

set +x
exec >&3 2>&4
exec 3<&- 4<&-

printf "#############################################################################\n"
printf "###                  Work completed: $(date +%Y-%m-%d:%H:%M:%S)                  ###\n"
printf "#############################################################################\n"
