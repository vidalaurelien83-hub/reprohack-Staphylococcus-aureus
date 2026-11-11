#!/bin/bash
# =====================================================================
# build_images.sh - Construit les images Apptainer du projet
# Recettes : container/*.def  ->  Images : images/*.sif
# Usage : bash build_images.sh           (saute les images déjà construites)
#         bash build_images.sh --force   (reconstruit tout)
# Prérequis : Apptainer installé (voir setup.sh), machine x86_64
# =====================================================================
set -euo pipefail

cd "$(dirname "$0")"     # se placer à la racine du dépôt
mkdir -p images

FORCE=false
[ "${1:-}" = "--force" ] && FORCE=true

# Bowtie 0.12.7, subread 1.4.6-p3 et les vieux paquets conda
# n'existent que pour les processeurs x86_64 (pas ARM)
if [ "$(uname -m)" != "x86_64" ]; then
    echo "ERREUR : architecture $(uname -m) non supportée (x86_64 requis)." >&2
    exit 1
fi

# --fakeroot si l'utilisateur y a droit, sinon sudo
if grep -q "^$USER:" /etc/subuid 2>/dev/null; then
    BUILD="apptainer build --fakeroot"
else
    BUILD="sudo apptainer build"
fi

# Une image par recette présente dans container/
for def in container/*.def; do
    name=$(basename "$def" .def)          # ex. cutadapt_1.11
    sif="images/$name.sif"
    if [ -f "$sif" ] && ! $FORCE; then
        echo "=== $name : déjà construite, ignorée"
        continue
    fi
    echo "=== $name : construction..."
    $BUILD --force "$sif" "$def"
done

echo
echo "=== Images disponibles ==="
ls -lh images/*.sif
