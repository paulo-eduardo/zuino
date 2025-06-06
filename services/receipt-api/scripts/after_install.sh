#!/bin/bash
set -e

echo "--- Hook AfterInstall iniciado ---"

DEPLOY_DIR="/var/www/html/services/receipt-api"
DATA_DIR_RELATIVE="data"

cd "$DEPLOY_DIR"
echo "Diretório atual: $(pwd)"

echo "Ajustando permissões do diretório de deploy para ec2-user..."
sudo chown -R ec2-user:ec2-user .

echo "Instalando dependencias de producao com 'npm ci --production'..."
npm ci --production

echo "Garantindo que o diretorio de dados '$DATA_DIR_RELATIVE/' exista..."
mkdir -p "$DATA_DIR_RELATIVE"

echo "--- Hook AfterInstall finalizado ---"

exit 0
