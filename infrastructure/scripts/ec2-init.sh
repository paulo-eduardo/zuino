#!/bin/bash
set -e

echo "--- Iniciando UserData Script para AL2023 ---"

echo "[UserData] Atualizando pacotes do sistema..."
sudo dnf update -y # Usa dnf

echo "[UserData] Instalando git..."
sudo dnf install -y git # Usa dnf

# Instala NVM (Node Version Manager)
echo "[UserData] Instalando NVM..."
# Executa como ec2-user (usuário padrão também no AL2023)
sudo -u ec2-user bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash'

# Instala Node.js v20 LTS via NVM (Deve funcionar no AL2023)
echo "[UserData] Instalando Node.js v20 LTS via NVM..."
# Usa 'bash -i -c' para garantir que .bashrc (com NVM) seja carregado na subshell
sudo -u ec2-user bash -i -c 'nvm install 20 && nvm alias default 20'

# Verifica a instalação do Node e NPM
echo "[UserData] Verificando instalação do Node.js..."
sudo -u ec2-user bash -i -c 'node -v && npm -v'

# Instala PM2 globalmente usando NVM's Node.js
echo "[UserData] Instalando PM2 globalmente..."
sudo -u ec2-user bash -i -c 'npm install pm2 -g'
echo "[UserData] PM2 instalado."

# Instala pré-requisitos do CodeDeploy Agent
echo "[UserData] Instalando pré-requisitos do CodeDeploy (ruby, wget)..."
sudo dnf install -y ruby wget # Usa dnf

# Baixa e instala o CodeDeploy Agent (método padrão deve funcionar)
echo "[UserData] Baixando e instalando o CodeDeploy Agent..."
EC2_REGION=$(ec2-metadata --availability-zone | sed 's/placement: \(.*\).$/\1/')
cd /home/ec2-user
wget https://aws-codedeploy-${EC2_REGION}.s3.${EC2_REGION}.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto
sudo systemctl start codedeploy-agent
sudo systemctl enable codedeploy-agent
echo "[UserData] Instalação do CodeDeploy Agent tentada."

# Garante que o agente SSM esteja rodando (geralmente pré-instalado)
echo "[UserData] Verificando e habilitando SSM Agent..."
sudo systemctl status amazon-ssm-agent || sudo systemctl start amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent

# Cria diretório da aplicação e ajusta permissões
echo "[UserData] Configurando diretório da aplicação..."
APP_DIR="/var/www/html/services/receipt-api"
sudo mkdir -p "$APP_DIR"
# Garante que o usuário ec2-user seja o dono
sudo chown -R ec2-user:ec2-user /var/www/html

echo "[UserData] Script finalizado com sucesso."
exit 0
