#!/bin/bash
# =====================================================================
# setup.sh - Installation des outils nécessaires au workflow
# Cible : VM Ubuntu 24.04 (noble) avec droits sudo
# Outils : Java 17, Nextflow, Apptainer, Damona
# Usage  : bash setup.sh   (peut être relancé sans risque)
# =====================================================================
set -euo pipefail

echo "=== 0/4 Réseau (DNS) ==="
# Sur le cloud IN2P3, les DNS fournis ne trouvent pas les miroirs Ubuntu
# (archive.ubuntu.com) : on bascule alors sur des DNS publics.
# Changement temporaire : après un redémarrage de la VM, relancer ce script.
if getent hosts archive.ubuntu.com >/dev/null; then
    echo "DNS OK"
else
    IFACE=$(ip route | awk '/default/ {print $5; exit}')
    sudo resolvectl dns "$IFACE" 1.1.1.1 8.8.8.8
    sudo resolvectl flush-caches
    echo "DNS publics configurés sur $IFACE"
fi


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
# Installé depuis le .deb officiel sur GitHub : le PPA Launchpad
# n'est pas joignable depuis le cloud (timeout sur api.launchpad.net).
APPTAINER_VERSION=1.4.5
if command -v apptainer >/dev/null 2>&1; then
    echo "Apptainer déjà installé"
else
    deb="apptainer_${APPTAINER_VERSION}_amd64.deb"
    wget -q -O "/tmp/$deb" \
        "https://github.com/apptainer/apptainer/releases/download/v${APPTAINER_VERSION}/$deb"
    sudo apt update || true   # || true : ignore les dépôts tiers injoignables
    sudo apt install -y "/tmp/$deb"
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