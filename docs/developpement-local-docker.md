# Developpement local Docker

Cet environnement restaure une copie locale de la prod a partir des backups existants:

- base: `/Users/admin/kabowd-local/backups/kabowd-prod-20260905.sql`
- uploads: `/Users/admin/kabowd-local/backups/kabowd-uploads-20260905.tar.gz`
- WordPress detecte dans le dump: `6.9.7`
- image WordPress locale par defaut: `wordpress:6.9-php8.3-apache`
- version WordPress forcee dans le volume local: `6.9.7-fr_CA`
- MariaDB detecte dans le dump: `11.4.5`
- domaine prod remplace localement: `kabowd.ca` vers `http://kabowd.localhost:8080`
- domaine multisite local: `kabowd.localhost:8080`
- theme parent requis: `biz-flick`
- theme enfant monte depuis ce repo: `kb-biz-flick-child`

## Demarrage rapide

```sh
cp .env.example .env
./scripts/local-reset.sh
```

Puis ouvrir:

- site: `http://kabowd.localhost:8080`
- admin WordPress: `http://kabowd.localhost:8080/wp-admin/`
- Adminer: `http://localhost:8081`
- Mailpit: `http://localhost:8025`

Identifiants Adminer:

- systeme: `MySQL`
- serveur: `db`
- utilisateur: `wordpress`
- mot de passe: `wordpress`
- base: `bitnami_wordpress`

## Flux de travail quotidien

```sh
docker compose up -d
docker compose run --rm wpcli
```

Les fichiers du theme enfant sont montes directement depuis ce repo. Une modification dans `functions.php`, `header.php`, `assets/`, etc. est donc visible dans le WordPress local sans rebuild d'image.

## Repartir d'une copie propre de la prod

```sh
./scripts/local-reset.sh
```

Cette commande supprime uniquement les volumes Docker de ce projet Compose, puis reimporte le dump SQL et les uploads. Les backups dans `/Users/admin/kabowd-local/backups` ne sont pas modifies.

## Notes importantes

- Le dump est multisite; la configuration locale garde les constantes reseau WordPress et remplace le domaine principal par `kabowd.localhost:8080`.
- Par defaut, le bootstrap active le theme enfant pour faciliter les tests. Pour garder le theme parent comme dans le dump, mettre `LOCAL_ACTIVATE_CHILD_THEME=false` dans `.env`, puis relancer `./scripts/local-reset.sh`.
- Les emails sortants sont rediriges vers Mailpit par le mu-plugin local.
- Les robots sont forces a `noindex, nofollow` localement.
- Les plugins detectes comme actifs reseau dans la prod sont installes par WP-CLI si `LOCAL_INSTALL_PROD_PLUGINS=true`.
- Le tag Docker patch exact `wordpress:6.9.7-php8.3-apache` n'etait pas publie lors de la validation; le tag officiel `wordpress:6.9-php8.3-apache` est utilise, puis WP-CLI met le volume local a `LOCAL_WORDPRESS_VERSION=6.9.7`. Si vous avez une image Docker exacte de la prod Bitnami/Lightsail, remplacer `WORDPRESS_IMAGE` dans `.env` avant le premier demarrage, puis relancer `./scripts/local-reset.sh`.
- Si `kabowd.localhost` ne resout pas sur votre machine, utiliser `http://localhost:8080` en mettant `WP_LOCAL_URL=http://localhost:8080` et `WP_LOCAL_HOST=localhost:8080` dans `.env`, puis relancer le reset.
