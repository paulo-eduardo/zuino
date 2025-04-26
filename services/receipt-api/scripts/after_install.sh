#!/bin/bash

set -e

echo "--- Hook AfterInstall iniciado ---"

DEPLOY_DIR="/var/www/html/services/receip-api"
DATA_DIR_RELATIVE="data"

cd "$DEPLOY_DIR"
echo "Diretorio atual: $(pwd)"

echo "Instalando dependencias de producao com 'npm ci --production'..."
npm ci --production

echo "Garantindo que o diretorio de dados '$DATA_DIR_RELATIVE/' exita..."
mkdir -p "$DATA_DIR_RELATIVE"

echo "--- Hook AfterInstall finalizado ---"

exit 0
