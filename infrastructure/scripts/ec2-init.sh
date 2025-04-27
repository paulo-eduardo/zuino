#!/bin/bash
set -e

echo "--- Iniciando UserData Script para AL2023 ---"

echo "[UserData] Atualizando pacotes do sistema..."
sudo dnf update -y

echo "[UserData] Instalando git..."
sudo dnf install -y git

# Instala Node.js v18 (LTS) diretamente via DNF
echo "[UserData] Instalando Node.js (v18) via dnf..."
sudo dnf install nodejs -y

echo "[UserData] Verificando instalação do Node.js..."
node -v
npm -v

echo "[UserData] Instalando PM2 globalmente..."
# Instala PM2 usando o npm do sistema (instalado com nodejs)
sudo npm install pm2 -g
echo "[UserData] PM2 instalado."

echo "[UserData] Instalando pré-requisitos do CodeDeploy (ruby, wget)..."
sudo dnf install -y ruby wget

echo "[UserData] Baixando e instalando o CodeDeploy Agent..."
EC2_REGION=$(ec2-metadata --region | awk '{print $2}')
# Usar /tmp para download temporário é seguro
cd /tmp
wget https://aws-codedeploy-${EC2_REGION}.s3.${EC2_REGION}.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto
sudo systemctl start codedeploy-agent
sudo systemctl enable codedeploy-agent
echo "[UserData] Instalação do CodeDeploy Agent tentada."

echo "[UserData] Verificando e habilitando SSM Agent..."
sudo systemctl status amazon-ssm-agent || sudo systemctl start amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent

echo "[UserData] Configurando diretório da aplicação..."
APP_DIR="/var/www/html/services/receipt-api"
sudo mkdir -p "$APP_DIR"
sudo chown -R ec2-user:ec2-user /var/www/html

echo "[UserData] Script finalizado com sucesso."
exit 0
