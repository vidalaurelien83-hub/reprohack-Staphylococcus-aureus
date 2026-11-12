# ReproHackathon 2026 – *Staphylococcus aureus* persisters


Le workflow est écrit avec **Nextflow** et chaque étape tourne dans un conteneur **Apptainer**, avec les versions d'outils de l'article.

## Différentes étapes de l'exécution

### Récupération du projet et installation des outils sur la machine virtuelle 

git clone https://github.com/vidalaurelien83-hub/reprohack-Staphylococcus-aureus.git

cd reprohack-Staphylococcus-aureus

bash setup.sh

exec bash

cd ~/reprohack-Staphylococcus-aureus

### Construire les images Apptainer

bash build_images.sh

### Lancer le workflow 

bash run.sh

### Récupération des figures

Dans le terminal du PC : 

scp ubuntu@<IP-DE-LA-VM>:~/reprohack-Staphylococcus-aureus/results/deseq2/*.pdf .


## Résultats

Figures obtenues avec ce workflow (copie de `results/deseq2/`) :
- [figures/MA_plot_all.pdf](figures/MA_plot_all.pdf) 
- [figures/MA_plot_translation.pdf](figures/MA_plot_translation.pdf)

