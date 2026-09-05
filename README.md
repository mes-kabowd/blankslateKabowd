# kb-biz-flick-child
## Thème enfant de Kabowd

## Contexte de ce répertoire
Étant donné que je supervise les travaux de stage de MAX dans le cadre du mandat de Kabowd Services informatiques. Je l'ai encouragé à faire du développement avec WordPress en développant un thène enfant.

## Comment réutiliser ce thème enfant
1. Installer WordPress dans un environnement local, conteneurisé ou non, ou en utilisant docker
2. [Installer le thème parent biz-flick](https://wordpress.org/themes/biz-flick/#:~:text=Welcome%20to%20Biz%20Flick%20the%20ultimate%20WordPress%20Full,SEO%20agencies%20looking%20to%20enhance%20their%20online%20presence)
3. Placer ce dossier dans le même répertoire dans lequel contient votre thème parent
5. Continuer à faire évoluer votre environnement

## Développement local Docker

Un environnement Docker local a été ajouté pour restaurer une copie de la prod avant validation:

```sh
cp .env.example .env
./scripts/local-reset.sh
```

Documentation complète: [docs/developpement-local-docker.md](docs/developpement-local-docker.md)
