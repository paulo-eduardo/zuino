#!/bin/bash
set -e

APP_NAME="receipt-api"
DEPLOY_DIR="/var/www/html/services/receipt-api"
PRESERVE_DIR_RELATIVE="data"

echo "--- Hook BeforeInstall iniciado ---"

if [ -d "$DEPLOY_DIR" ]; then
  cd "$DEPLOY_DIR"
  echo "Diretorio atual: $(pwd)"

  pm2 describe $APP_NAME >/dev/null 2>&1
  PM2_EXISTS=$?

  if [ "$PM2_EXISTS" -eq 0 ]; then
    echo "Parando aplicacao '$APP_NAME' gerenciada pelo PM2..."
    pm2 stop $APP_NAME || true
  else
    echo "Aplicacao '$APP_NAME' nao encontrada no PM2 ou ja parada. Pulando parada."
  fi

  echo "Limpando diretorio de deploy '$DEPLOY_DIR' (excluindo $PRESERVE_DIR_RELATIVE/)..."
  find . -mindepth 1 ! -ipath "./$PRESERVE_DIR_RELATIVE*" -delete || true
  echo "Limpeza concluida."

else
  echo "Diretorio de deploy '$DEPLOY_DIR' nao existe (primeiro deploy?). Pulando limpeza."
  mkdir -p "$DEPLOY_DIR"
fi

echo "--- Hook BeforeInstall finalizado ---"
exit 0
