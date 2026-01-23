# Psono Deployment Guide – Phase 1 (Local Lab)

## Overview

This guide covers **Phase 1** of the Psono deployment: setting up a functional lab environment on a local Ubuntu Server VM.

**Objectives:**
- Install and configure Docker + Docker Compose
- Deploy Psono Server with PostgreSQL
- Validate web UI and basic functionality
- Document the setup for reproducibility

**Duration:** ~15-20 minutes (after Ubuntu installation)

---

## Prerequisites

### Hardware
- VM: 2+ CPU cores, 2+ GB RAM recommended
- Disk: 20+ GB available
- Network: Internet access for package downloads

### Software
- Ubuntu Server 22.04 LTS (minimal installation)
- SSH access to the VM
- Git (optional, for cloning the repository)

### Credentials
- SSH key for passwordless access
- Admin user with sudo privileges (no root login)

---

## Step 1: Prepare the VM

### 1.1 Initial Setup (if not already done)

```bash
# Connect to VM via SSH
ssh -i /path/to/key.pem admin@vm-ip

# Verify Ubuntu version
cat /etc/os-release
# Expected: Ubuntu 22.04 LTS

# Update system
sudo apt-get update
sudo apt-get upgrade -y
```

### 1.2 Verify Network & Access

```bash
# Check internet connectivity
ping -c 3 google.com

# Check DNS
nslookup docker.io

# Verify sudo access
sudo whoami
# Expected output: root
```

---

## Step 2: Clone Repository

```bash
# Clone the Psono project
git clone <your-repo-url> ~/psono-lab
cd ~/psono-lab

# Verify structure
ls -la
# Expected: docker/, terraform/, scripts/, docs/, etc.
```

---

## Step 3: Run Bootstrap Script

The `bootstrap.sh` script automates Docker installation and configuration.

### 3.1 Option A: Local File

```bash
# Make script executable
chmod +x scripts/bootstrap.sh

# Run with sudo
sudo bash scripts/bootstrap.sh
```

### 3.2 Option B: Direct Download (if hosting on web)

```bash
# Download and run directly (use cautiously!)
# curl -sSL https://your-domain.com/bootstrap.sh | sudo bash
```

### 3.3 What bootstrap.sh Does

✅ Updates system packages  
✅ Installs Docker CE (Community Edition)  
✅ Installs Docker Compose  
✅ Starts Docker service  
✅ Enables Docker on system startup  
✅ Verifies installation  

### 3.4 Verify Installation

```bash
# Check Docker version
docker --version
# Expected: Docker version 20.10+ or 24.0+

# Check Docker Compose
docker-compose --version
# Expected: Docker Compose version 2.0+

# Test Docker (should print "Hello from Docker!")
sudo docker run --rm hello-world
```

---

## Step 4: Configure Environment Variables

### 4.1 Copy Template

```bash
cd docker
cp .env.example .env
```

### 4.2 Edit .env File

```bash
nano .env
```

**Critical settings to customize:**

```bash
# Database
DB_PASSWORD=your-secure-password-here    # Change!

# Psono Admin (temporary - must change on first login)
PSONO_ADMIN_PASSWORD=SecurePassword@123  # Change!

# Security Key
SECRET_KEY=your-random-secret-key        # Change! Use:
# python3 -c "import secrets; print(secrets.token_urlsafe(50))"

# Network (restrict in production)
CORS_ALLOWED_ORIGINS=http://localhost,http://127.0.0.1
ALLOWED_HOSTS=*
```

**⚠️ IMPORTANT:** Do NOT commit `.env` to Git! It's in `.gitignore`.

---

## Step 5: Start Psono Stack

### 5.1 Launch Containers

```bash
# Ensure you're in the docker directory
cd ~/psono-lab/docker

# Pull latest images and start services
docker-compose pull
docker-compose up -d

# Expected output:
# Creating network "docker_psono-network" with driver "bridge"
# Creating psono-postgres ... done
# Creating psono-server ... done
# Creating psono-nginx ... done
```

### 5.2 Verify Services are Running

```bash
# List running containers
docker-compose ps

# Expected output:
# NAME                COMMAND                  SERVICE      STATUS              PORTS
# psono-nginx         "nginx -g 'daemon of"   nginx        Up 2 seconds        0.0.0.0:80->80/tcp
# psono-server        "/app/entrypoint.sh"    psono        Up 8 seconds (healthy) 8000/tcp
# psono-postgres      "docker-entrypoint.s"   postgres     Up 12 seconds (healthy)
```

### 5.3 Check Container Health

```bash
# View logs for all services
docker-compose logs -f

# View logs for specific service
docker-compose logs -f psono
docker-compose logs -f postgres
docker-compose logs -f nginx

# Exit logs: Ctrl+C
```

---

## Step 6: Access Psono Web UI

### 6.1 Determine Server IP

```bash
# On VM
hostname -I
# Example output: 192.168.1.100

# Or from local machine (if VM is accessible)
ssh -i key.pem admin@vm-ip 'hostname -I'
```

### 6.2 Open in Browser

**From local machine:**

```
http://192.168.1.100
```

**Expected:**
- Psono login page loads
- No SSL warnings (HTTP only in Phase 1)

### 6.3 First Login

**Credentials (from .env):**
```
Username: admin
Password: <PSONO_ADMIN_PASSWORD from .env>
```

**After successful login:**
- ✅ Dashboard loads
- ✅ Can navigate menu
- ✅ System is functional

---

## Step 7: Validate Functionality

### 7.1 Database Check

```bash
# Connect to PostgreSQL container
docker-compose exec postgres psql -U psono -d psono

# List tables (inside psql)
\dt

# Check table counts
SELECT COUNT(*) FROM auth_user;

# Exit psql
\q
```

### 7.2 Container Resource Usage

```bash
# Check container stats
docker stats --no-stream

# Expected: All containers running, memory < 500MB each
```

### 7.3 Nginx Reverse Proxy

```bash
# Test nginx configuration
docker-compose exec nginx nginx -t

# Expected: 
# nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
# nginx: configuration will be successful
```

### 7.4 Create Test Secret

In Psono Web UI:

1. **Login** with admin credentials
2. **Create a new safe**
3. **Add a secret** (e.g., test password)
4. **Logout and login** to verify persistence
5. **Verify the secret** is still there

✅ If all works → **Phase 1 Complete!**

---

## Troubleshooting

### "Port 80 already in use"

```bash
# Find process using port 80
sudo lsof -i :80

# Kill conflicting process (if safe)
sudo kill -9 <PID>

# Or change port in docker-compose.yml:
# ports:
#   - "8080:80"  # Access via http://ip:8080
```

### Container exits immediately

```bash
# Check exit code and logs
docker-compose logs psono
docker-compose logs postgres

# Common causes:
# - .env file missing or invalid
# - Database password mismatch
# - Insufficient disk space
```

### Database connection refused

```bash
# Verify PostgreSQL is healthy
docker-compose ps postgres
# STATUS should show "(healthy)"

# Restart PostgreSQL
docker-compose restart postgres

# Wait 10 seconds for startup
sleep 10
docker-compose ps
```

### Psono UI doesn't load

```bash
# Verify nginx is running
docker-compose logs nginx

# Test reverse proxy connectivity
docker-compose exec nginx curl -s http://psono:8000/

# Restart nginx if needed
docker-compose restart nginx
```

### Forgot admin password

```bash
# Create new admin user in container
docker-compose exec psono python manage.py createsuperuser

# Or reset via Django shell (advanced)
docker-compose exec psono python manage.py shell
# >>> from django.contrib.auth.models import User
# >>> u = User.objects.get(username='admin')
# >>> u.set_password('NewPassword123')
# >>> u.save()
# >>> exit()
```

---

## Persistence & Data

### Volumes

Data is persisted in Docker volumes:

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect docker_postgres_data
docker volume inspect docker_psono_data
```

**Survive:**
- Container stop/restart
- Container deletion

**Lost on:**
- Volume deletion (`docker-compose down -v`)

### Backups (Manual)

```bash
# Backup PostgreSQL
docker-compose exec postgres pg_dump -U psono psono > backup_$(date +%Y%m%d).sql

# Restore backup
cat backup_20260120.sql | docker-compose exec -T postgres psql -U psono psono
```

---

## Next Steps

After Phase 1 validation:

### Immediate (before Phase 2)
- [ ] Document any issues encountered
- [ ] Test backup/restore procedures
- [ ] Create admin user policy documentation
- [ ] Plan initial user onboarding

### Phase 2 (Terraform IaC)
- [ ] Create Terraform configuration for EC2
- [ ] Set up AWS credentials
- [ ] Test `terraform plan` locally
- [ ] Prepare for AWS deployment

---

## Security Notes – Phase 1

⚠️ **This is a LAB environment. NOT production-ready:**

- ✅ No HTTPS (HTTP only)
- ✅ Secrets in plaintext `.env` file
- ✅ Postgres accessible only internally (good)
- ✅ SSH key-based auth (good)
- ❌ Wide CORS allowed (`*`)
- ❌ Debug mode disabled (good)
- ❌ Temporary admin password

**Differences from Phase 3 (Production):**
- Phase 1: Local HTTP only
- Phase 3: HTTPS with AWS ACM, ALB, restricted SGs, KMS encryption

---

## Useful Commands

```bash
# Start services
docker-compose up -d

# Stop services (data persists)
docker-compose stop

# Stop and remove containers (data persists in volumes)
docker-compose down

# Remove everything including volumes (⚠️ deletes all data!)
docker-compose down -v

# View logs in real-time
docker-compose logs -f

# Execute command in running container
docker-compose exec psono bash
docker-compose exec postgres psql -U psono -d psono

# Rebuild images after code change
docker-compose build --no-cache

# Update images from registry
docker-compose pull

# Full status check
docker-compose ps && docker stats --no-stream
```

---

## Validation Checklist

- [ ] Docker installed and running
- [ ] Docker Compose version 2.0+
- [ ] All containers in `docker-compose ps` show "Up"
- [ ] Psono web UI loads at `http://<vm-ip>`
- [ ] Can login with admin credentials
- [ ] Can create and view secrets
- [ ] Database contains user data
- [ ] Nginx reverse proxy working
- [ ] Bootstrap script can be re-run safely
- [ ] `.env` file is not in Git
- [ ] Volumes persist data after restart

---

## References

- [Psono Official Docs](https://doc.psono.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [PostgreSQL Docker Image](https://hub.docker.com/_/postgres)
- [Nginx Best Practices](https://nginx.org/en/docs/)

---

**Last Updated:** 20 de janeiro de 2026  
**Status:** Phase 1 Documentation Complete  
**Next:** Phase 2 – Terraform IaC
