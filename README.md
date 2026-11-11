# ReproHackathon 2026 – *Staphylococcus aureus* persisters


Le workflow est écrit avec **Nextflow** et chaque étape tourne dans un conteneur **Apptainer**, avec les versions d'outils de l'article.

## Lancer l'analyse

```bash
bash setup.sh          # installe Java, Nextflow, Apptainer et Damona
bash build_images.sh   # construit les images à partir des recettes de container/
bash run.sh            # lance le workflow Nextflow
```