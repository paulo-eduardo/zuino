#!/bin/bash
yum update -y
# Install Git
yum install git -y
# Install NVM (Node Version Manager) and Node LTS
su - ec2-user -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash"
su - ec2-user -c "source ~/.bashrc && nvm install --lts && nvm alias default 'lts/*'"
# Install PM2 globally using the installed Node version
su - ec2-user -c "source ~/.bashrc && npm install pm2 -g"
# Install CodeDeploy Agent prerequisites
yum install ruby wget -y
# Download and install CodeDeploy Agent
# Determine region from instance metadata
EC2_AVAIL_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
EC2_REGION=$(echo "$EC2_AVAIL_ZONE" | sed 's/[a-z]$//')
cd /home/ec2-user
wget https://aws-codedeploy-${EC2_REGION}.s3.${EC2_REGION}.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto
sudo systemctl start codedeploy-agent
sudo systemctl enable codedeploy-agent
# Ensure SSM Agent is running (usually installed on AL2)
systemctl status amazon-ssm-agent || systemctl start amazon-ssm-agent
systemctl enable amazon-ssm-agent
# Create application directory and set permissions
APP_DIR="/var/www/html/services/receipt-api"
mkdir -p $APP_DIR
chown -R ec2-user:ec2-user /var/www/html
