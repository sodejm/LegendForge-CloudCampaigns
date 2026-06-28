#!/bin/bash
set -e

# D&D Foundry VTT - Azure VM Initialization Script
echo "[$(date)] Starting Foundry initialization..."

# Update system packages
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y curl wget git nodejs npm docker.io monitoring-agent jq

# Enable and start Docker
systemctl enable docker
systemctl start docker
usermod -aG docker $USER

# Create Foundry directories
mkdir -p /opt/foundry/data /opt/foundry/config /opt/foundry/logs

# Create docker-compose file for Foundry
cat > /opt/foundry/docker-compose.yml << 'COMPOSEFILE'
version: '3.8'
services:
  foundry:
    image: felddy/foundryvtt:${foundry_version}
    restart: always
    ports:
      - "30000:30000"
    environment:
      - FOUNDRY_LICENSE_KEY=${foundry_license_key}
    volumes:
      - /opt/foundry/data:/data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:30000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
COMPOSEFILE

# Start Foundry
cd /opt/foundry && docker-compose up -d
sleep 30

echo "[$(date)] Foundry initialization completed!"
