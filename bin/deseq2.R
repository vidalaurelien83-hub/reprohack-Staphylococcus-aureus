#!/usr/bin/env Rscript
# =====================================================================
# deseq2.R - Analyse différentielle persisters vs contrôles
#            (R 3.4.1 / DESeq2 1.16.1, versions de l'article)
# Usage   : Rscript deseq2.R counts.txt samples.csv
# Sorties : deseq2_results.tsv  résultats complets (un gène par ligne)
#           MA_plot_all.pdf     MA-plot de tous les gènes (Supp. Fig. 3)
# =====================================================================
suppressMessages(library(DESeq2))

args         <- commandArgs(trailingOnly = TRUE)
counts_file  <- args[1]
samples_file <- args[2]

# --- 1. Lecture des comptages (sortie de featureCounts) --------------
# comment.char = "#" : ignore la 1re ligne (commande featureCounts)
counts <- read.table(counts_file, header = TRUE, sep = "\t",
                     comment.char = "#", check.names = FALSE)
# gene-SAOUHSC_00001 -> SAOUHSC_00001 (identifiant stable, comparable aux auteurs)
rownames(counts) <- sub("^gene-", "", counts$Geneid)
# on garde seulement les 6 colonnes de comptages, sans l'extension .bam
counts <- counts[, grep("\\.bam$", colnames(counts))]
colnames(counts) <- sub("\\.bam$", "", colnames(counts))

# --- 2. Plan d'expérience (samples.csv) ------------------------------
samples <- read.csv(samples_file, stringsAsFactors = FALSE)
rownames(samples) <- samples$sample
counts <- counts[, samples$sample]      # même ordre que samples.csv
# "control" = référence : log2FC > 0 veut dire plus exprimé chez les persisters
samples$condition <- factor(samples$condition, levels = c("control", "persister"))

# --- 3. DESeq2 avec les paramètres par défaut (comme l'article) ------
dds <- DESeqDataSetFromMatrix(countData = as.matrix(counts),
                              colData   = samples,
                              design    = ~ condition)
dds <- DESeq(dds)
# filtrage indépendant (défaut) + correction de Benjamini-Hochberg
res <- results(dds, alpha = 0.05)

# --- 4. Export des résultats et bilan --------------------------------
out <- data.frame(gene = rownames(res), as.data.frame(res))
write.table(out, "deseq2_results.tsv", sep = "\t", quote = FALSE, row.names = FALSE)

sig <- !is.na(res$padj) & res$padj < 0.05
cat("Gènes testés           :", nrow(res), "\n")
cat("DEG (padj < 0.05)      :", sum(sig), "(article : 1477)\n")
cat("  up chez persisters   :", sum(sig & res$log2FoldChange > 0), "(article : 710)\n")
cat("  down chez persisters :", sum(sig & res$log2FoldChange < 0), "(article : 767)\n")

# --- 5. MA-plot de tous les gènes (Supp. Fig. 3) ---------------------
ma     <- out[out$baseMean > 0, ]                  # échelle log : pas de zéro
lim    <- 4                                         # axe Y borné à ±4 comme l'article
y      <- pmax(pmin(ma$log2FoldChange, lim), -lim)
hors   <- abs(ma$log2FoldChange) > lim              # points hors cadre -> triangles
is_sig <- !is.na(ma$padj) & ma$padj < 0.05

pdf("MA_plot_all.pdf", width = 7, height = 5)
plot(ma$baseMean, y, log = "x", ylim = c(-lim, lim),
     pch = ifelse(hors, 17, 20), cex = 0.6,
     col = ifelse(is_sig, "red", "black"),
     xlab = "Mean of normalized counts", ylab = "log2 fold change",
     main = "Persisters vs contrôles (tous les gènes)")
abline(h = 0, lty = 2, col = "grey40")
legend("bottomright", legend = c("padj < 0.05", "non significatif"),
       col = c("red", "black"), pch = 20, bty = "n")
invisible(dev.off())
