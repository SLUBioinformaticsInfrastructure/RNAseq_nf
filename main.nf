#!/usr/bin/env nextflow

/*
===============================================================
SLUBI/rnaseq
===============================================================
 RNA-Seq Analysis Pipeline. Started November 2018.
 #### Homepage / Documentation
https://...
 #### Authors
Oskar Karlsson-Lindsjö <>
Juliette Hayer <>
---------------------------------------------------------------
*/


// Configurable variables
params.name = false
params.project = false
params.genome = false
params.readsPath = false

// Validate inputs
if ( params.fasta ){
    fasta = file(params.fasta)
    if( !fasta.exists() ) exit 1, "Fasta file not found: ${params.fasta}"
}
else {
    exit 1, "No reference genome specified!"
}


// The reference genome file 
genome_file = file(params.genome)

/*
 * Creates the `read_pairs` channel that emits for each read-pair a tuple containing
 * three elements: the pair ID, the first read-pair file and the second read-pair file
 */
Channel
    .fromFilePairs( params.readsPath + '*_{R1,R2}_001.fastq.gz', size: 2, flat: true)
    .ifEmpty { error "Cannot find any reads matching: ${params.reads}" }
    .into { read_pairs_multiqc_raw ; read_pairs_fastp_raw }

/*
* Trimming quality and adapters with fastp
*/
process trimming_pe {
    //container: add fastp container. ex:'jdidion/atropos'
    publishDir params.output, mode: 'copy'

    input:
        set val(id), file(read1), file(read2) from read_pairs_fastp_raw

    output:
        set val(id), file("${id}_R1_trimmed.fastq"), file("${id}_R2_trimmed.fastq") into {trimmed_reads_pe ; trimmed_pe_trinity ; trimmed_pe_salmon}

    script:
        """
        fastp -i $read1 -o ${id}_R1_trimmed.fastq -I $read2 -O ${id}_R2_trimmed.fastq \
            --detect_adapter_for_pe --qualified_quality_phred 30 \
            --cut_by_quality5 --cut_by_quality3 --cut_mean_quality 30 --html ${id}_fastp_report.html
        """
}

process fastqc {
    //container 'hadrieng/fastqc'

    input:
    file reads from trimmed_reads_pe.merge(read_pairs_multiqc_raw)
    //    file raw_reads from read_pairs_multiqc_raw
    //    file trimmed_reads from trimmed_reads_pe

    output:
        file "*_fastqc.{zip,html}" into fastqc_results

    script:
        """
        fastqc -t 4 $reads 
        """
}

process multiqc {
    //container 'ewels/multiqc'
    publishDir 'results', mode: 'copy'

    input:
        file 'fastqc/*' from fastqc_results.collect()

    output:
        file 'multiqc_report.html'

    script:
        """
        multiqc .
        """
}