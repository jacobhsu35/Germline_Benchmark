#!/bin/bash
#PBS -q ngs192G
#PBS -P MST109178
#PBS -W group_list=MST109178
#PBS -N bedintersect_select
#PBS -j oe 
#PBS -M s0890003@gmail.com
#PBS -m e

OUTPUT_PATH="/work2/lynn88065/Dragen/Pipeline_compare/WES_benchmark/20201210/query_vcf_select"
cd $OUTPUT_PATH


# TOOL DIRECTORY
GATK="/project/GP1/u3710062/AI_SHARE/software/GATK/GenomeAnalysisTK-3.6/GenomeAnalysisTK.jar"
bedtools="/pkg/biology/BEDTools/BEDTools_v2.27.1/bin/bedtools"
fasta="/project/GP1/u3710062/AI_SHARE/reference/From_illumina/reference_illumina/hg38.fa"


# GIAB HighconfBed
GIAB="/project/GP1/u3710062/AI_SHARE/reference/GIAB"
HG001_highconf_BED="$GIAB/NA12878_HG001/NISTv3.3.2/GRCh38/HG001_GRCh38_GIAB_highconf_CG-IllFB-IllGATKHC-Ion-10X-SOLID_CHROM1-X_v.3.3.2_highconf_nosomaticdel_noCENorHET7.bed"
HG002_highconf_BED="$GIAB/AshkenazimTrio/HG002_NA24385_son/NISTv3.3.2/GRCh38/HG002_GRCh38_GIAB_highconf_CG-Illfb-IllsentieonHC-Ion-10XsentieonHC-SOLIDgatkHC_CHROM1-22_v.3.3.2_highconf_noinconsistent.bed"
HG003_highconf_BED="$GIAB/AshkenazimTrio/HG003_NA24149_father/NISTv3.3.2/GRCh38/HG003_GRCh38_GIAB_highconf_CG-Illfb-IllsentieonHC-Ion-10XsentieonHC_CHROM1-22_v.3.3.2_highconf_noinconsistent.bed"
HG004_highconf_BED="$GIAB/AshkenazimTrio/HG004_NA24143_mother/NISTv3.3.2/GRCh38/HG004_GRCh38_GIAB_highconf_CG-Illfb-IllsentieonHC-Ion-10XsentieonHC_CHROM1-22_v.3.3.2_highconf_noinconsistent.bed"


# Target bed file
# hg38 (already liftover from hg19)
# IDT_v1 (xGen Exome Research Panel v1 targets)
IDT_v1="/work2/lynn88065/Dragen/Pipeline_compare/WES_benchmark/BedFileForVC/IDT_v1_hg38_vc.bed"

# IDT_v2 (xGen Exome Research Panel v1 targets)
IDT_v2="/work2/lynn88065/Dragen/Pipeline_compare/WES_benchmark/BedFileForVC/IDT_v2_hg38_vc.bed"

# GIAB_original VCF
# HG001
HG001_VCF="$GIAB/NA12878_HG001/NISTv3.3.2/GRCh38/HG001_GRCh38_GIAB_highconf_CG-IllFB-IllGATKHC-Ion-10X-SOLID_CHROM1-X_v.3.3.2_highconf_PGandRTGphasetransfer.vcf.gz"
# HG002
HG002_VCF="$GIAB/AshkenazimTrio/HG002_NA24385_son/NISTv3.3.2/GRCh38/HG002_GRCh38_GIAB_highconf_CG-Illfb-IllsentieonHC-Ion-10XsentieonHC-SOLIDgatkHC_CHROM1-22_v.3.3.2_highconf_triophased.vcf.gz"


# Query original VCF
# DRAGEN_v3.6.3
Q1="DRAGEN_v3.6"
Query1="/work2/lynn88065/Dragen/Outputs/Benchmark/NHRI_HG001/WES/hg38/v3.6.3/NHRI_NA12878_HG001_hg38/Dragen_NHRI_NA12878_HG001_hg38.hard-filtered.vcf.gz"
# GATK_v4.1
Q2="GATK_v4.1"
Query2="/work2/lynn88065/GATK/Outputs/20201209_WES_benchmark/NHRI_NA12878_HG001/NHRI_NA12878_HG001.bwamem.marked.recal.pass1.indexed.filtered.haplotype.SnpIndel.vcf.gz"
# Nvidia_Parabricks
Q3="Nvidia_Parabricks"
Query3="/work2/lynn88065/Rawdata/20201209_Nvidia_Parabricks/ILMN_hg38/WES/output_wes_illuminahg38.vcf"
# WASAI
Q4="WASAI_LightningPlus"
Query4="/project/GP1/jeff1wasai/nhri/na12878/wes/NHRI_NA12878_WES_ILMN_hg38/NHRI_NA12878_WES_ILMN_hg38.vcf.gz"

# Bed intersect
# HG001 highconf bed intersect IDT_v1
#$bedtools intersect -a $HG001_highconf_BED -b $IDT_v1 > $OUTPUT_PATH/HG001_GRCh38_GIAB_highconf_bedintersect_IDT_v1.bed
bed1=/work2/lynn88065/Dragen/Pipeline_compare/WES_benchmark/BedFileForBenchmark/HG001_GRCh38_GIAB_highconf_bedintersect_IDT_v1.bed

# GATK_selectvariants (bedinterect HG001/IDT_v1)
# Q1
java -Xmx48g -jar $GATK \
         -T SelectVariants \
         -R $fasta \
         -V $Query1 \
         -L $bed1 \
         -o $OUTPUT_PATH/WES_GIAB_HG001_selectvariants_bedinterect_IDT_v1_${Q1}_output.vcf

# Q2
java -Xmx48g -jar $GATK \
         -T SelectVariants \
         -R $fasta \
         -V $Query2 \
         -L $bed1 \
         -o $OUTPUT_PATH/WES_GIAB_HG001_selectvariants_bedinterect_IDT_v1_${Q2}_output.vcf
     
# Q3
java -Xmx48g -jar $GATK \
         -T SelectVariants \
         -R $fasta \
         -V $Query3 \
         -L $bed1 \
         -o $OUTPUT_PATH/WES_GIAB_HG001_selectvariants_bedinterect_IDT_v1_${Q3}_output.vcf
         
# Q4
java -Xmx48g -jar $GATK \
         -T SelectVariants \
         -R $fasta \
         -V $Query4 \
         -L $bed1 \
         -o $OUTPUT_PATH/WES_GIAB_HG001_selectvariants_bedinterect_IDT_v1_${Q4}_output.vcf
                 
