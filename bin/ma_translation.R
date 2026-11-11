#!/usr/bin/env Rscript
# =====================================================================
# ma_translation.R - MA-plot des gènes liés à la traduction (Fig. 3c)
# Usage   : Rscript ma_translation.R deseq2_results.tsv kegg_sao00001.keg aureowiki_NCTC8325.tsv
# Sorties : MA_plot_translation.pdf, translation_genes.tsv
# =====================================================================
args <- commandArgs(trailingOnly = TRUE)
res  <- read.delim(args[1], stringsAsFactors = FALSE)

# --- 1. Gènes liés à la traduction d'après KEGG (organisme "sao") ----
# Hypothèse (l'article cite seulement "KEGG Orthology") : on retient
#   03010 Ribosome, 00970 Aminoacyl-tRNA biosynthesis,
#   03012 Translation factors, 03009 Ribosome biogenesis,
#   03016 Transfer RNA biogenesis
keg     <- readLines(args[2])
cats    <- c("03010", "00970", "03012", "03009", "03016")
genes   <- character(0)
aars    <- character(0)
current <- ""
for (l in keg) {
  if (grepl("^C ", l)) current <- sub("^C +([0-9]+) .*", "\\1", l)
  if (grepl("^D ", l) && current %in% cats) {
    id    <- regmatches(l, regexpr("SAOUHSC_[0-9]+", l))
    genes <- c(genes, id)
    # aminoacyl-ARNt synthétases = enzymes EC 6.1.1.x
    if (current == "00970" && grepl("EC:6\\.1\\.1\\.", l)) aars <- c(aars, id)
  }
}
genes <- unique(genes)
aars  <- unique(aars)

# --- 2. Noms courts des gènes (AureoWiki, colonne "pan gene symbol") --
aw        <- read.delim(args[3], stringsAsFactors = FALSE, quote = "")
names_map <- setNames(aw[[2]], aw[[1]])          # SAOUHSC_01236 -> frr

# --- 3. Sélection des gènes de la traduction -------------------------
tr        <- res[res$gene %in% genes & res$baseMean > 0, ]
tr$symbol <- names_map[tr$gene]
tr$sig    <- !is.na(tr$padj) & tr$padj < 0.05
tr$aars   <- tr$gene %in% aars
write.table(tr, "translation_genes.tsv", sep = "\t", quote = FALSE, row.names = FALSE)
cat("Gènes de la traduction :", nrow(tr), "dont", sum(tr$sig), "significatifs\n")

# --- 4. MA-plot (même présentation que la Fig. 3c) --------------------
x <- log2(tr$baseMean)
y <- tr$log2FoldChange
pdf("MA_plot_translation.pdf", width = 6, height = 6)
plot(x, y, pch = 20, col = ifelse(tr$sig, "red", "grey50"),
     xlim = c(0, 20), ylim = c(-6, 5),
     xlab = "Log2 base Mean", ylab = "Log2 Fold Change",
     main = "Gènes liés à la traduction")
abline(h = 0, lty = 2)
# cercle noir autour des aminoacyl-ARNt synthétases
points(x[tr$aars], y[tr$aars], pch = 1, cex = 1.3, lwd = 1.5)
# noms des gènes mis en avant dans l'article
a_nommer <- c("frr", "infA", "infB", "infC", "tsf", "pth")
lab <- tr$symbol %in% a_nommer
text(x[lab], y[lab], labels = tr$symbol[lab], pos = 4, font = 3, cex = 0.9)
legend("bottomleft", c("Significant", "Non-significant", "AA-tRNA synthetases"),
       pch = c(20, 20, 1), col = c("red", "grey50", "black"), bty = "n")
invisible(dev.off())
