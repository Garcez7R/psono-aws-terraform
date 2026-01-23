#!/bin/bash
# Psono Zero-Touch Setup Script
# Compatible with Ubuntu 22.04 Minimal

set -e

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log "🚀 Iniciando setup automatizado do Psono..."

# 1. Instalar dependências básicas (necessário para Ubuntu Minimal)
log "📦 Instalando dependências básicas..."
sudo apt-get update -qq
sudo apt-get install -y -qq curl wget git openssl jq

# 2. Instalar Docker se não existir
if ! command -v docker &> /dev/null; then
    log "🐳 Instalando Docker..."
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker $USER
fi

# 3. Gerar .env automaticamente se não existir
DOTENV_PATH="$(dirname "$0")/../docker/.env"
if [ ! -f "$DOTENV_PATH" ]; then
    log "🔐 Gerando configurações e senhas seguras..."
    DB_PASS=$(openssl rand -base64 18)
    ADMIN_PASS=$(openssl rand -base64 12)
    SECRET_KEY=$(openssl rand -base64 48)
    
    cat > "$DOTENV_PATH" << EOF
DB_NAME=psono
DB_USER=psono
DB_PASSWORD=$DB_PASS
SECRET_KEY=$SECRET_KEY
DEBUG=False
PSONO_ADMIN_USERNAME=admin
PSONO_ADMIN_PASSWORD=$ADMIN_PASS
CORS_ALLOWED_ORIGINS=http://localhost,http://127.0.0.1
ALLOWED_HOSTS=*
TZ=UTC
EOF
    log "✅ Arquivo .env gerado com sucesso!"
    log "--------------------------------------------------"
    log "📝 CREDENCIAIS INICIAIS GERADAS:"
    log "Usuário: admin"
    log "Senha: $ADMIN_PASS"
    log "--------------------------------------------------"
fi

# 4. Subir o Docker Compose
log "🚢 Subindo os containers..."
cd "$(dirname "$0")/../docker"
# Forçar a recriação para garantir que as novas variáveis sejam aplicadas
sudo docker compose down
sudo docker compose pull -q
sudo docker compose up -d

log "⏳ Aguardando inicialização (30s)..."
sleep 30

log "✅ Psono está pronto!"
log "Acesse em: http://$(hostname -I | awk '{print $1}')"
