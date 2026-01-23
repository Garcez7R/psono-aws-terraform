#!/bin/bash

# Psono Server – Health Check & Status Script
# Usage: ./scripts/health-check.sh
# Check container health, database connectivity, and web UI availability

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Psono Server – Health Check"
echo "=========================================="
echo ""

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ docker-compose not found${NC}"
    exit 1
fi

# Change to docker directory
if [ -f "docker/docker-compose.yml" ]; then
    cd docker
fi

echo "📊 Container Status:"
docker-compose ps

echo ""
echo "🔍 Detailed Health Checks:"
echo ""

# Check PostgreSQL
echo -n "PostgreSQL (postgres): "
if docker-compose ps postgres 2>/dev/null | grep -q "Up"; then
    HEALTH=$(docker-compose exec -T postgres pg_isready -U psono 2>/dev/null || echo "failed")
    if [[ "$HEALTH" == *"accepting"* ]]; then
        echo -e "${GREEN}✅ Healthy${NC}"
    else
        echo -e "${YELLOW}⚠️ Running but may not be ready${NC}"
    fi
else
    echo -e "${RED}❌ Not running${NC}"
fi

# Check Psono Server
echo -n "Psono Server (psono): "
if docker-compose ps psono 2>/dev/null | grep -q "Up"; then
    echo -e "${GREEN}✅ Running${NC}"
else
    echo -e "${RED}❌ Not running${NC}"
fi

# Check Nginx
echo -n "Nginx (nginx): "
if docker-compose ps nginx 2>/dev/null | grep -q "Up"; then
    echo -e "${GREEN}✅ Running${NC}"
else
    echo -e "${RED}❌ Not running${NC}"
fi

echo ""
echo "💾 Resource Usage:"
docker stats --no-stream 2>/dev/null || echo "Docker stats unavailable"

echo ""
echo "📡 Network Check:"
docker-compose exec -T nginx curl -s http://psono:8000/ > /dev/null 2>&1 && \
    echo -e "${GREEN}✅ Nginx → Psono connectivity: OK${NC}" || \
    echo -e "${RED}❌ Nginx → Psono connectivity: FAILED${NC}"

echo ""
echo "🌐 Web UI Check:"
curl -s http://localhost/ > /dev/null 2>&1 && \
    echo -e "${GREEN}✅ Web UI accessible: http://localhost${NC}" || \
    echo -e "${RED}❌ Web UI not accessible${NC}"

echo ""
echo "📊 Database Statistics:"
docker-compose exec -T postgres psql -U psono -d psono -c "
    SELECT 
        (SELECT COUNT(*) FROM auth_user) as users,
        (SELECT COUNT(*) FROM django_session) as sessions,
        pg_size_pretty(pg_database_size('psono')) as db_size;
" 2>/dev/null || echo "Cannot connect to database"

echo ""
echo "=========================================="
echo "✅ Health check complete"
echo "=========================================="
