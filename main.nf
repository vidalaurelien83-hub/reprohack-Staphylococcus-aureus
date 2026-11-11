#!/usr/bin/env nextflow
/*

 * Étapes : téléchargement FASTQ + génome -> index Bowtie -> trimming cutadapt
 * (puis : mapping Bowtie, comptage featureCounts, DESeq2)
 */
nextflow.enable.dsl = 2

// Téléchargement d'un échantillon depuis l'ENA
process DOWNLOAD_FASTQ {
    tag "$srr"
    storeDir "${params.datadir}/fastq"

    input:
    val srr

    output:
    tuple val(srr), path("${srr}.fastq.gz")

    script:
    def dir = "${srr[0..5]}/0${srr[-2..-1]}/${srr}"
    """
    wget -q -O ${srr}.fastq.gz https://ftp.sra.ebi.ac.uk/vol1/fastq/${dir}/${srr}.fastq.gz
    """
}

// Génome de référence + annotation (S. aureus NCTC 8325, CP000253.1)
process DOWNLOAD_GENOME {
    storeDir "${params.datadir}/reference"

    output:
    path "reference.fasta", emit: fasta
    path "reference.gff",   emit: gff

    script:
    """
    wget -q -O reference.fasta "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=${params.ref_id}&rettype=fasta"
    wget -q -O reference.gff   "https://www.ncbi.nlm.nih.gov/sviewer/viewer.cgi?db=nuccore&report=gff3&id=${params.ref_id}"
    """
}

// Index Bowtie
process BOWTIE_INDEX {
    publishDir "${params.outdir}/index", mode: 'copy'

    input:
    path fasta

    output:
    path "index*.ebwt"

    script:
    """
    bowtie-build ${fasta} index
    """
}

// Trimming cutadapt (-q 20 = hypothèse à justifier dans le rapport)
process TRIM {
    tag "$srr"
    publishDir "${params.outdir}/trimmed", mode: 'copy'

    input:
    tuple val(srr), path(fastq)

    output:
    tuple val(srr), path("${srr}.trimmed.fastq.gz")

    script:
    """
    cutadapt -q 20 -m 25 -o ${srr}.trimmed.fastq.gz ${fastq}
    """
}

workflow {
    srr_ch   = Channel.fromList(params.samples)
    fastq_ch = DOWNLOAD_FASTQ(srr_ch)
    genome   = DOWNLOAD_GENOME()
    index_ch = BOWTIE_INDEX(genome.fasta)
    trim_ch  = TRIM(fastq_ch)
}