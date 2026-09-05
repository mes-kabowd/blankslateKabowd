#!/bin/sh
set -eu

WP_PATH="${WP_PATH:-/var/www/html}"
LOCAL_URL="${WP_LOCAL_URL:-http://kabowd.localhost:8080}"
LOCAL_HOST="${WP_LOCAL_HOST:-kabowd.localhost}"
PROD_HOST="${WP_PROD_HOST:-kabowd.ca}"
PARENT_THEME="${LOCAL_PARENT_THEME:-biz-flick}"
CHILD_THEME="${LOCAL_CHILD_THEME:-kb-biz-flick-child}"
ACTIVATE_CHILD_THEME="${LOCAL_ACTIVATE_CHILD_THEME:-true}"
INSTALL_PROD_PLUGINS="${LOCAL_INSTALL_PROD_PLUGINS:-true}"
PROD_PLUGINS="${LOCAL_PROD_PLUGINS:-jetpack the-post-grid ultimate-addons-for-gutenberg smtp-amazon-ses w3-total-cache wordpress-importer}"
TARGET_WORDPRESS_VERSION="${LOCAL_WORDPRESS_VERSION:-6.9.7}"
WORDPRESS_LOCALE="${LOCAL_WORDPRESS_LOCALE:-fr_CA}"

case "$LOCAL_HOST" in
  *"'"*|*";"*|*" "*)
    echo "WP_LOCAL_HOST invalide: $LOCAL_HOST"
    exit 1
    ;;
esac

cd "$WP_PATH"

attempt=0
until [ -f "$WP_PATH/wp-config.php" ]; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 80 ]; then
    echo "wp-config.php introuvable apres l'attente du conteneur WordPress."
    exit 1
  fi
  sleep 2
done

attempt=0
until wp db check --path="$WP_PATH" --allow-root >/dev/null 2>&1; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 120 ]; then
    echo "La base WordPress importee n'est pas encore accessible par WP-CLI."
    exit 1
  fi
  sleep 3
done

echo "Ajustement du domaine multisite vers $LOCAL_HOST"
wp db query "UPDATE wp_blogs SET domain = '$LOCAL_HOST', path = '/' WHERE blog_id = 1;" --path="$WP_PATH" --allow-root
wp db query "UPDATE wp_site SET domain = '$LOCAL_HOST', path = '/' WHERE id = 1;" --path="$WP_PATH" --allow-root

attempt=0
until wp option get siteurl --url="$LOCAL_URL" --path="$WP_PATH" --allow-root >/dev/null 2>&1; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 120 ]; then
    echo "WordPress ne trouve toujours pas le site local $LOCAL_URL apres la correction multisite."
    exit 1
  fi
  sleep 3
done

echo "Remplacement des URLs de prod par $LOCAL_URL"
wp search-replace "https://www.$PROD_HOST" "$LOCAL_URL" --all-tables --skip-columns=guid --precise --recurse-objects --report-changed-only --path="$WP_PATH" --allow-root
wp search-replace "http://www.$PROD_HOST" "$LOCAL_URL" --all-tables --skip-columns=guid --precise --recurse-objects --report-changed-only --path="$WP_PATH" --allow-root
wp search-replace "https://$PROD_HOST" "$LOCAL_URL" --all-tables --skip-columns=guid --precise --recurse-objects --report-changed-only --path="$WP_PATH" --allow-root
wp search-replace "http://$PROD_HOST" "$LOCAL_URL" --all-tables --skip-columns=guid --precise --recurse-objects --report-changed-only --path="$WP_PATH" --allow-root
wp search-replace "//$PROD_HOST" "//$LOCAL_HOST" --all-tables --skip-columns=guid --precise --recurse-objects --report-changed-only --path="$WP_PATH" --allow-root

wp option update home "$LOCAL_URL" --url="$LOCAL_URL" --path="$WP_PATH" --allow-root
wp option update siteurl "$LOCAL_URL" --url="$LOCAL_URL" --path="$WP_PATH" --allow-root
wp site option update siteurl "$LOCAL_URL/" --path="$WP_PATH" --allow-root
wp site option update subdomain_install 1 --path="$WP_PATH" --allow-root

if [ -n "$TARGET_WORDPRESS_VERSION" ]; then
  CURRENT_WORDPRESS_VERSION="$(wp core version --path="$WP_PATH" --allow-root)"
  if [ "$CURRENT_WORDPRESS_VERSION" != "$TARGET_WORDPRESS_VERSION" ]; then
    echo "Ajustement de WordPress vers $TARGET_WORDPRESS_VERSION ($WORDPRESS_LOCALE)"
    wp core update --version="$TARGET_WORDPRESS_VERSION" --force --locale="$WORDPRESS_LOCALE" --url="$LOCAL_URL" --path="$WP_PATH" --allow-root
    wp core update-db --network --url="$LOCAL_URL" --path="$WP_PATH" --allow-root
  fi
fi

if ! wp theme is-installed "$PARENT_THEME" --path="$WP_PATH" --allow-root >/dev/null 2>&1; then
  echo "Installation du theme parent $PARENT_THEME"
  wp theme install "$PARENT_THEME" --force --path="$WP_PATH" --allow-root
fi

if [ "$INSTALL_PROD_PLUGINS" = "true" ]; then
  for plugin in $PROD_PLUGINS; do
    if ! wp plugin is-installed "$plugin" --path="$WP_PATH" --allow-root >/dev/null 2>&1; then
      echo "Installation du plugin $plugin"
      if ! wp plugin install "$plugin" --force --path="$WP_PATH" --allow-root; then
        echo "Attention: installation impossible pour $plugin. Le site local peut quand meme tourner, mais il sera moins proche de la prod."
      fi
    fi
  done
fi

if [ "$ACTIVATE_CHILD_THEME" = "true" ]; then
  echo "Activation du theme enfant $CHILD_THEME"
  wp theme activate "$CHILD_THEME" --url="$LOCAL_URL" --path="$WP_PATH" --allow-root
else
  echo "Activation du theme parent $PARENT_THEME"
  wp theme activate "$PARENT_THEME" --url="$LOCAL_URL" --path="$WP_PATH" --allow-root
fi

wp rewrite flush --hard --url="$LOCAL_URL" --path="$WP_PATH" --allow-root
wp cache flush --url="$LOCAL_URL" --path="$WP_PATH" --allow-root

echo "Environnement local pret: $LOCAL_URL"
