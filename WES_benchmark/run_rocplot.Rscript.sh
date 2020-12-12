#!/bin/bash

# * There must be a version of Rscript available in the PATH.
# * The ggplot2 package must be installed in R

OUTPUT_PATH="/work2/lynn88065/Dragen/Pipeline_compare/WES_benchmark/20201210/rocplot"
cd $OUTPUT_PATH

#Template="/work2/lynn88065/Dragen/Pipeline_compare/20200130"
Template="/project/GP1/u3710062/AI_SHARE/shared_scripts/hap.py/INPUT"
export PATH=/pkg/biology/R/R_v3.6.2/bin:$PATH

# HG001
# hg38
# Output prefix name
f1="NHRI_HG001_hg38_DRAGEN_v3.6"
f2="NHRI_HG001_hg38_GATK_v4.1"
f3="NHRI_HG001_hg38_Nvidia_Parabricks"
f4="NHRI_HG001_hg38_WASAI_LightningPlus"

echo
echo "----------------------------------------------------------------------------------"
echo
echo "Making plots (this replaces plots in the doc folder of this checkout!)"

# Compare with different caller performance
${Template}/rocplot_test.Rscript ${OUTPUT_PATH}/WES_benchmark_hg38_HG001 \
        ${f1}-ve:DRAGEN_v3.6 ${f2}-ve:GATK_v4.1 ${f3}-ve:Nvidia_Parabricks ${f4}-ve:WASAI_LightningPlus -pr


