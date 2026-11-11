#!/usr/bin/env Rscript
# =====================================================================
# compare_reference.R - Compare nos résultats DESeq2 à ceux des auteurs
# Usage   : Rscript compare_reference.R deseq2_results.tsv GSE139659_IPvsctrl.complete.xls.gz
# Sorties : comparison_log2FC.pdf, comparison_discordant.tsv (+ bilan affiché)
# =====================================================================
args <- commandArgs(trailingOnly = TRUE)
ours <- read.delim(args[1], stringsAsFactors = FALSE)
# fichier des auteurs (GEO) : texte tabulé compressé, format SARTools
ref  <- read.delim(gzfile(args[2]), stringsAsFactors = FALSE, quote = "")

# --- 1. Appariement des gènes par locus tag (SAOUHSC_xxxxx) ----------
# Les "Id" des auteurs (gene0, gene1...) viennent d'une ancienne version
# du GFF NCBI : on compare donc via la colonne Name (locus tag stable).
ref$gene <- ref$Name
m <- merge(ours, ref[, c("gene", "baseMean", "log2FoldChange", "padj")],
           by = "gene", suffixes = c(".nous", ".auteurs"))
sig_nous    <- !is.na(m$padj.nous)    & m$padj.nous    < 0.05
sig_auteurs <- !is.na(m$padj.auteurs) & m$padj.auteurs < 0.05
meme_sens   <- sign(m$log2FoldChange.nous) == sign(m$log2FoldChange.auteurs)

# --- 2. Bilan chiffré -------------------------------------------------
cat("=== Gènes analysés ===\n")
cat("Nous              :", nrow(ours), "\n")
cat("Auteurs (GEO)     :", nrow(ref), "\n")
cat("Communs           :", nrow(m), "\n")
cat("Seulement auteurs :", paste(setdiff(ref$gene, ours$gene), collapse = " "), "\n\n")

cat("=== Gènes différentiellement exprimés (padj < 0.05) ===\n")
cat("Article (texte)   : 1477\n")
cat("Auteurs (GEO)     :", sum(!is.na(ref$padj)  & ref$padj  < 0.05), "\n")
cat("Nous              :", sum(!is.na(ours$padj) & ours$padj < 0.05), "\n")
cat("DEG communs       :", sum(sig_nous & sig_auteurs), "\n")
cat("  dont même sens  :", sum(sig_nous & sig_auteurs & meme_sens), "\n")
cat("Seulement nous    :", sum(sig_nous & !sig_auteurs), "\n")
cat("Seulement auteurs :", sum(!sig_nous & sig_auteurs), "\n\n")

cat("=== Corrélation (gènes communs) ===\n")
cat("log2FoldChange    : r =", round(cor(m$log2FoldChange.nous, m$log2FoldChange.auteurs,
                                         use = "complete.obs"), 4), "\n")
cat("baseMean (log10)  : r =", round(cor(log10(m$baseMean.nous + 1), log10(m$baseMean.auteurs + 1),
                                         use = "complete.obs"), 4), "\n")

# --- 3. Gènes discordants (DEG chez l'un mais pas chez l'autre) -------
disc <- m[sig_nous != sig_auteurs,
          c("gene", "baseMean.nous", "log2FoldChange.nous", "padj.nous",
            "log2FoldChange.auteurs", "padj.auteurs")]
write.table(disc, "comparison_discordant.tsv", sep = "\t", quote = FALSE, row.names = FALSE)

# --- 4. Graphique : nos log2FC en fonction de ceux des auteurs ---------
couleur <- ifelse(sig_nous & sig_auteurs, "red",
           ifelse(sig_nous | sig_auteurs, "orange", "grey60"))
pdf("comparison_log2FC.pdf", width = 6, height = 6)
plot(m$log2FoldChange.auteurs, m$log2FoldChange.nous, pch = 20, cex = 0.5, col = couleur,
     xlab = "log2 fold change - auteurs (GEO)", ylab = "log2 fold change - nous",
     main = "Persisters vs contrôles : nous vs auteurs")
abline(0, 1, lty = 2)   # diagonale = résultats identiques
legend("topleft", c("DEG chez les deux", "DEG chez un seul", "non DEG"),
       col = c("red", "orange", "grey60"), pch = 20, bty = "n")
invisible(dev.off())
