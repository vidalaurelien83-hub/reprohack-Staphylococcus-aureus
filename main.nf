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

// Trimming cutadapt : adaptateur TruSeq (-a), qualité (-q 20 = hypothèse),
// longueur minimale 25 nt (-m 25, comme dans l'article)

process TRIM {
    tag "$srr"
    publishDir "${params.outdir}/trimmed", mode: 'copy'

    input:
    tuple val(srr), path(fastq)

    output:
    tuple val(srr), path("${srr}.trimmed.fastq.gz")

    script:
    """
        cutadapt -a ${params.adapter} -q 20 -m 25 -o ${srr}.trimmed.fastq.gz ${fastq}
    """
}

// Mapping Bowtie 0.12.7 (paramètres par défaut, comme dans l'article),
// puis tri et indexation du BAM avec samtools (même image)
process MAPPING {
    tag "$srr"
    publishDir "${params.outdir}/bam", mode: 'copy'

    input:
    tuple val(srr), path(fastq)
    path index                       // les 6 fichiers index*.ebwt

    output:
    tuple val(srr), path("${srr}.bam"), path("${srr}.bam.bai"), emit: bam
    path "${srr}.bowtie.log",                                   emit: log

    script:
    """
    set -o pipefail
    bowtie -p ${task.cpus} -S index <(gunzip -c ${fastq}) 2> ${srr}.bowtie.log \\
        | samtools sort -@ ${task.cpus} -o ${srr}.bam -
    samtools index ${srr}.bam
    """
}

// Comptage des lectures par gène avec featureCounts 1.4.6-p3
// (paramètres de l'article : -t gene -g ID -s 1 = librairie orientée)
process COUNT {
    publishDir "${params.outdir}/counts", mode: 'copy'

    input:
    path bams                        // les 6 BAM d'un coup
    path gff

    output:
    path "counts.txt",         emit: counts
    path "counts.txt.summary", emit: summary

    script:
    """
    featureCounts -t gene -g ID -s 1 -F GTF -T ${task.cpus} \\
        -a ${gff} -o counts.txt ${bams}
    """
}


workflow {
    srr_ch   = Channel.fromList(params.samples)
    fastq_ch = DOWNLOAD_FASTQ(srr_ch)
    genome   = DOWNLOAD_GENOME()
    index_ch = BOWTIE_INDEX(genome.fasta)
    trim_ch  = TRIM(fastq_ch)

    // Mapping : chaque échantillon nettoyé + le même index pour tous
    MAPPING(trim_ch, index_ch)

    // Comptage : on rassemble les 6 BAM en une seule liste
    bams_ch  = MAPPING.out.bam.map { srr, bam, bai -> bam }.collect()
    COUNT(bams_ch, genome.gff)
}
