# 6 sequences de l'article


wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR103/021/SRR10379721/SRR10379721.fastq.gz
wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR103/026/SRR10379726/SRR10379726.fastq.gz
wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR103/022/SRR10379722/SRR10379722.fastq.gz
wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR103/025/SRR10379725/SRR10379725.fastq.gz
wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR103/023/SRR10379723/SRR10379723.fastq.gz
wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR103/024/SRR10379724/SRR10379724.fastq.gz


# Génome de référence + annotation (S. aureus NCTC 8325, CP000253.1)
[ -s reference.fasta ] || wget -O reference.fasta "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=CP000253.1&rettype=fasta"
[ -s reference.gff ]   || wget -O reference.gff "https://www.ncbi.nlm.nih.gov/sviewer/viewer.cgi?db=nuccore&report=gff3&id=CP000253.1"
