
task CTAT_FUSION_TASK {

    File input_bam
    File genome_lib_tar_gz
    String sample_name

    command {

    set -e

    # initial potential cleanup of read names in the bam file
    /usr/local/bin/sam_readname_cleaner.py ${input_bam} ${input_bam}.cleaned.bam


    # revert aligned bam
    java -Xmx1000m -jar /usr/local/bin/picard.jar \
        RevertSam \
        INPUT=${input_bam}.cleaned.bam \
        OUTPUT_BY_READGROUP=false \
        VALIDATION_STRINGENCY=SILENT \
        SORT_ORDER=queryname \
        OUTPUT=${sample_name}.reverted.bam 


    # bam to fastq
    java -jar /usr/local/bin/picard.jar \
        SamToFastq I=${sample_name}.reverted.bam \
        F=${sample_name}_1.fastq F2=${sample_name}_2.fastq \
        INTERLEAVE=false NON_PF=true \
        CLIPPING_ATTRIBUTE=XT CLIPPING_ACTION=2

    # untar the genome lib
    tar xvf ${genome_lib_tar_gz}

    # starFusion

    /usr/local/bin/STAR-Fusion \
         --left_fq ${sample_name}_1.fastq \
         --right_fq ${sample_name}_2.fastq \
	 --CPU 16 \
         --genome_lib_dir $(echo $(basename ${genome_lib_tar_gz}) | sed s/.plug-n-play.tar.gz//)/ctat_genome_lib_build_dir \
         --output_dir ${sample_name}
	 

	cp ${sample_name}/star-fusion.fusion_predictions.abridged.tsv  ${sample_name}.star-fusion.fusion_predictions.abridged.tsv
	

    }
    
    output {
      File star_fusion_results="${sample_name}.star-fusion.fusion_predictions.abridged.tsv"
    }

    runtime {
            docker: "trinityctat/firecloud_ctatfusion:0.0.2"
            disks: "local-disk 200 SSD"
            memory: "50G"
            cpu: "16"
    }


}

workflow ctat_fusion_wf {

    String sample_name
    File rnaseq_aligned_bam
    File genome_lib_tar_gz

    call CTAT_FUSION_TASK {
        input: input_bam=rnaseq_aligned_bam,
	       sample_name=sample_name,
               genome_lib_tar_gz=genome_lib_tar_gz
    }

    

}


