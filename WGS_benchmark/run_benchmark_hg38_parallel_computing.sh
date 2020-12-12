#!/bin/bash
#PBS -q nhri192G
#PBS -l select=1:ncpus=10
#PBS -P MST109178
#PBS -W group_list=MST109178
#PBS -N WGS_Benchmark_hg38
#PBS -j oe
#PBS -M s0890003@gmail.com
#PBS -m e
#
# Small benchmark using hap.py / vcfeval
#
# Author: Peter Krusche <pkrusche@illumina.com>
#
# This script needs the following things:
#
# * a working hap.py build. This script can e.g. be run from a build folder
# * hap.py must have been built with VCFEval support. This means we need Java
# * There must be a version of Rscript available in the PATH.
# * The ggplot2 package must be installed in R
#
# This script will take a while to run, ca. 20-30 min on a 4-core laptop.
# Running with more CPUs will be faster.

ID="NHRI_HG001_hg38_SAMPLE_NAME" #Output prefix name
HG="hg38"
Date="20201210"
workdir="/work2/lynn88065/Dragen/Pipeline_compare/WGS_benchmark/${Date}"
mkdir -p $workdir/rocplot
cd $workdir/rocplot

# Tool directory
DIR="/pkg/biology/hap.py/build/hap.py/example/happy"
PYTHON="/pkg/biology/Python/Python2_default/bin/python"
HC="/pkg/biology/hap.py/hap.py_v0.3.10/bin/hap.py"
rtg="/pkg/biology/rtg-tools/rtg-tools_v3.10/rtg"
sdf_38="/work2/lynn88065/Dragen/Pipeline_compare/sdf/hg38_ILMN_sdf"

# GRCh38 (TRUTH VCF & BED)
GIAB="/project/GP1/u3710062/AI_SHARE/reference/GIAB"
# HG001
TRUTH_VCF_hg38="$GIAB/NA12878_HG001/NISTv3.3.2/GRCh38/HG001_GRCh38_GIAB_highconf_CG-IllFB-IllGATKHC-Ion-10X-SOLID_CHROM1-X_v.3.3.2_highconf_PGandRTGphasetransfer.vcf.gz"
BED_conf_hg38="$GIAB/NA12878_HG001/NISTv3.3.2/GRCh38/HG001_GRCh38_GIAB_highconf_CG-IllFB-IllGATKHC-Ion-10X-SOLID_CHROM1-X_v.3.3.2_highconf_nosomaticdel_noCENorHET7.bed"

REF_38="/project/GP1/u3710062/AI_SHARE/reference/From_illumina/reference_illumina/hg38.fa"
export HGREF=${REF_38}

Query="QUERY_VCF"

##################################################################################
############################## WGS benchmark######################################
##################################################################################

$PYTHON $HC $TRUTH_VCF_hg38 $Query -f $BED_conf_hg38 -r $REF_38 -o ${ID}-ve --engine-vcfeval-path $rtg --engine=vcfeval --engine-vcfeval-template $sdf_38
