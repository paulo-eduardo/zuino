#!/bin/bash
set -e

APP_NAME="receipt-api"
DEPLOY_DIR="/var/www/html/services/receipt-api"
START_SCRIPT="dist/index.js"

cd "$DEPLOY_DIR"
echo "Diretorio atual: $(pwd)"

pm2 describe $APP_NAME >/dev/null 2>&1
PM2_EXISTS=$?

if [ "$PM2_EXISTS" -eq 0 ]; then
  echo "Recarregando aplicacao '$APP_NAME' com PM2 (reload)..."
  pm2 reload $APP_NAME --update-env
else
  echo "Iniciando aplicacao '$APP_NAME' com PM2 (start)..."
  pm2 start "$START_SCRIPT" --name "$APP_NAME"
fi

echo "Salvando lista de processos PM2..."
pm2 save || true

echo "--- Hook ApplicationStart finalizado ---"

exit 0
