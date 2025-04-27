#!/bin/bash

echo "--- Hook ValidateService iniciado ---"

APP_PORT=3000
HEALTH_CHECK_URL="http://localhost:${APP_PORT}/health"
MAX_RETRIES=5
RETRY_INTERVAL=5
RETRY_COUNT=0

echo "Validando se o servico esta acessivel em $HEALTH_CHECK_URL..."
echo "(Tentando $MAX_RETRIES vezes com intervalo de $RETRY_INTERVAL segundos)"

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if curl -f -s -o /dev/null "$HEALTH_CHECK_URL"; then
    echo "Validacao bem-sucedida na tentativa $((RETRY_COUNT + 1))! O servico esta respondendo na porta $APP_PORT."
    exit 0
  else
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
      echo "Tentativa $RETRY_COUNT falhou. Tentando novamente em $RETRY_INTERVAL segundos..."
      sleep $RETRY_INTERVAL
    fi
  fi
done

echo "Validacao FALHOU apos $MAX_RETRIES tentativas. O servico pode nao ter iniciado corretamente."
exit 1
