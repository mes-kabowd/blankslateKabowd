#!/bin/sh
set -eu

docker compose down --volumes --remove-orphans
docker compose up -d db restore-uploads wordpress adminer mailpit
docker compose run --rm wpcli
docker compose ps
