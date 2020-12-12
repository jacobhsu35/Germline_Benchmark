
wkdir=/work2/lynn88065/Dragen/Pipeline_compare/WES_benchmark/20201210
Template=$wkdir/run_benchmark_hg38_parallel_computing.sh
#Template=$wkdir/run_annotation_DE.sh
#sample_list=$wkdir/sample_list.txt
sample_list=/work2/lynn88065/Dragen/Pipeline_compare/WES_benchmark/20201210/sample_list.txt

while read -r subject VCF_PATH; 
	do
	cd $wkdir &&
	sed -i "s|SAMPLE_NAME|$subject|g" $Template &&
    sed -i "s|QUERY_VCF|$VCF_PATH|g" $Template &&
	qsub $Template &&
        sleep 10s &&
        sed -i "s|$subject|SAMPLE_NAME|g" $Template &&
        sed -i "s|$VCF_PATH|QUERY_VCF|g" $Template 

	done<$sample_list
