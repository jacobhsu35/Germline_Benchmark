# Germline_Benchmark

## Brief introduction 

The inputs to hap.py are two VCF files (a "truth" and a "query" file), and an optional "confident call region" bed file. 
> NOTE: bed files with track information are not supported, all input bed or bed.gz files must only contain bed records.

You can find more detailed information [Hap.py User's Manual](https://github.com/Illumina/hap.py/blob/master/doc/happy.md)


## Processing Steps

### Running benchmark

```
run_benchmark_hg38_parallel_computing.sh
```


### Bed intersect and selectvariant for WES 
bedtool intrersect allows one to screen for "overlap" betwenn two sets of genomic features. 
Select a subset of variants from VCF file using GATK tool.

```
run_bedintersect_select.sh
```

### ROC curves
Hap.py can create data for ROC-style curves. Normally, it is preferable to calculate such curves based on the input variant representations, and not to perform any variant splitting or preprocessing.

```
run_rocplot.Rscript.sh
`````
Any set of hap.py runs can be plotted like this using the script [run_rocplot.Rscript.sh](https://github.com/YenlingPeng/Germline_Benchmark/blob/master/WGS_benchmark/run_rocplot.Rscript.sh)

#### WGS benchmark Result
|![SNVs](https://github.com/YenlingPeng/Germline_Benchmark/blob/master/WGS_benchmark/rocplot/WGS_benchmark_hg38_HG001.SNP.png)|![INDELs](https://github.com/YenlingPeng/Germline_Benchmark/blob/master/WGS_benchmark/rocplot/WGS_benchmark_hg38_HG001.INDEL.png)|

#### WES benchmark Result

|![SNVs](https://github.com/YenlingPeng/Germline_Benchmark/blob/master/WES_benchmark/rocplot/WES_benchmark_hg38_HG001.SNP.png)|![INDELs](https://github.com/YenlingPeng/Germline_Benchmark/blob/master/WES_benchmark/rocplot/WES_benchmark_hg38_HG001.INDEL.png)|



