#!/bin/bash
# =====================================================================
# setup.sh - Installation des outils nécessaires au workflow
# Cible : VM Ubuntu 24.04 (noble) avec droits sudo
# Outils : Java 17, Nextflow, Apptainer, Damona
# Usage  : bash setup.sh   (peut être relancé sans risque)
# =====================================================================
set -euo pipefail

echo "=== 1/4 Java 17 (requis par Nextflow) ==="
if java -version 2>&1 | grep -qE 'version "(1[7-9]|2[0-9])'; then
    echo "Java déjà installé"
else
    sudo apt update
    sudo apt install -y openjdk-17-jre-headless
fi

echo "=== 2/4 Nextflow ==="
if command -v nextflow >/dev/null 2>&1; then
    echo "Nextflow déjà installé"
else
    cd /tmp
    curl -s https://get.nextflow.io | bash
    sudo mv nextflow /usr/local/bin/
    sudo chmod +x /usr/local/bin/nextflow
    cd - >/dev/null
fi

echo "=== 3/4 Apptainer ==="
if command -v apptainer >/dev/null 2>&1; then
    echo "Apptainer déjà installé"
else
    sudo apt install -y software-properties-common
    sudo add-apt-repository -y ppa:apptainer/ppa
    sudo apt update
    sudo apt install -y apptainer
fi

echo "=== 4/4 Damona (via pipx) ==="
if command -v pipx >/dev/null 2>&1; then
    echo "pipx déjà installé"
else
    sudo apt install -y pipx
fi
export PATH="$HOME/.local/bin:$PATH"
if command -v damona >/dev/null 2>&1; then
    echo "Damona déjà installé"
else
    pipx install damona
    pipx ensurepath
fi

echo
echo "=== Vérification ==="
ok=true
for tool in java nextflow apptainer damona; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "  [OK]       $tool"
    else
        echo "  [MANQUANT] $tool"; ok=false
    fi
done
java -version 2>&1 | head -1
nextflow -version 2>/dev/null | grep -i version || true
apptainer --version
damona --version 2>/dev/null || true

if $ok; then
    echo "Tout est installé. Ouvrez un nouveau terminal (ou tapez: exec bash)."
else
    echo "Un outil manque : voir les messages ci-dessus." >&2
    exit 1
fi