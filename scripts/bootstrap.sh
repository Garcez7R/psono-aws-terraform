#!/bin/bash
set -e

# Psono Server – Phase 1 Bootstrap Script
# Runs on: Ubuntu Server 22.04 LTS
# Purpose: Install Docker, Docker Compose, and start Psono stack
# Usage: curl -sSL <script-url> | bash

echo "=========================================="
echo "Psono Server – Phase 1 Bootstrap"
echo "=========================================="
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root"
   exit 1
fi

# Update system
echo "📦 Updating system packages..."
apt-get update -qq
apt-get upgrade -y -qq

# Install Docker prerequisites
echo "🐋 Installing Docker prerequisites..."
apt-get install -y -qq \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    apt-transport-https

# Add Docker GPG key and repository
echo "🔑 Adding Docker repository..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package lists
apt-get update -qq

# Install Docker
echo "🐋 Installing Docker..."
apt-get install -y -qq \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# Verify Docker installation
echo "✅ Docker installed:"
docker --version

# Install Docker Compose standalone (additional)
echo "🔧 Installing Docker Compose standalone..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4 | sed 's/v//')
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "✅ Docker Compose installed:"
docker-compose --version

# Start Docker service
echo "🚀 Starting Docker service..."
systemctl start docker
systemctl enable docker

# Verify Docker is running
echo "✅ Docker service status:"
systemctl status docker --no-pager

echo ""
echo "=========================================="
echo "✅ Phase 1 Bootstrap Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Clone the repository: git clone <repo-url>"
echo "2. Navigate to docker dir: cd docker"
echo "3. Copy .env: cp .env.example .env"
echo "4. Edit .env with your values"
echo "5. Start Psono: docker-compose up -d"
echo "6. Check status: docker-compose ps"
echo "7. View logs: docker-compose logs -f psono"
echo ""
echo "Access Psono at: http://<your-server-ip>"
echo ""
