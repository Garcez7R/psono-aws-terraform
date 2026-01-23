# Psono Lab – Execution Guide

> Professional case study: Deploying open-source password manager with Docker + Terraform

---

## 🚀 30-Minute Quick Start

### Phase 1: Local Testing (15 min)

```bash
# 1. Prepare your .env file
cd docker
cp .env.example .env

# Edit critical values:
# DB_PASSWORD=MySecurePass@123
# PSONO_ADMIN_PASSWORD=AdminPass@123
# SECRET_KEY=<generated-secret-key>
nano .env

# 2. Start the stack
docker-compose up -d

# 3. Verify it's running
docker-compose ps
# All should show "Up"

# 4. Access in browser
# http://localhost
# Login: admin / <PSONO_ADMIN_PASSWORD>
```

✅ **Phase 1 Complete** – Psono running locally

---

### Phase 2: AWS Deployment (15 min)

```bash
# Prerequisites: AWS credentials configured
aws sts get-caller-identity  # Should return your account info

# 1. Configure Terraform
cd terraform
cp terraform.tfvars.example terraform.tfvars

# Edit critical values:
# aws_region = "us-east-1"
# repository_url = "https://github.com/YOUR/PsOno.git"
# psono_admin_password = "AdminPass@123"
# db_password = "PgPass@123"
# secret_key = <generated-secret-key>
# allowed_ssh_cidrs = ["YOUR_IP/32"]  # IMPORTANT: Restrict!
nano terraform.tfvars

# 2. Initialize and validate
terraform init
terraform validate

# 3. Deploy (review plan first!)
terraform plan
terraform apply

# 4. Get access details
terraform output psono_web_url
terraform output ssh_connection_command
```

✅ **Phase 2 Complete** – Psono running on AWS EC2

---

## 📋 Detailed Workflows

### Phase 1: Full Docker Setup

#### Setup from Scratch
```bash
# 1. Install Docker (if not already installed)
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 2. Or use our bootstrap script
sudo bash scripts/bootstrap.sh

# 3. Start Psono
cd docker
cp .env.example .env
# Edit .env with secure passwords
docker-compose up -d
```

#### Verify Deployment
```bash
# Check containers
docker-compose ps

# View logs
docker-compose logs -f psono

# Access web UI
# Browser: http://localhost
# User: admin
# Password: <from .env>

# Health check script
bash ../scripts/health-check.sh
```

#### Manage Stack
```bash
# Stop temporarily
docker-compose stop

# Start again
docker-compose start

# Stop and remove containers (data persists)
docker-compose down

# Stop and remove everything including data ⚠️
docker-compose down -v

# Update images
docker-compose pull
docker-compose up -d

# Execute commands in containers
docker-compose exec psono python manage.py createsuperuser
docker-compose exec postgres psql -U psono -d psono
```

---

### Phase 2: Full Terraform Deployment

#### Prerequisites
```bash
# 1. AWS Credentials
aws configure
# Enter: Access Key ID, Secret Access Key, Region, Output format

# Verify
aws sts get-caller-identity

# 2. Terraform
terraform --version  # Should be 1.0+

# 3. SSH Key
ssh-keygen -t ed25519 -f ~/.ssh/psono-lab -N "" -C "psono-lab"
```

#### Deploy Step-by-Step
```bash
# 1. Navigate to terraform directory
cd terraform

# 2. Copy and customize configuration
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars

# Critical settings:
#   aws_region = "us-east-1"
#   instance_type = "t3.small"
#   repository_url = "https://github.com/YOUR/PsOno.git"
#   psono_admin_password = "NewSecurePassword@123"
#   db_password = "DatabasePassword@123"
#   secret_key = "min-32-characters-secret-key"
#   allowed_ssh_cidrs = ["YOUR_IP/32"]  ← IMPORTANT!

# 3. Initialize Terraform
terraform init

# 4. Validate configuration
terraform validate

# 5. Review what will be created
terraform plan -out=tfplan

# 6. Deploy to AWS
terraform apply tfplan

# Expected: ~3-5 minutes for full deployment

# 7. Get connection information
terraform output

# Example outputs:
#   psono_web_url = "http://203.0.113.100"
#   ssh_connection_command = "ssh -i ~/.ssh/psono-lab ubuntu@203.0.113.100"
```

#### Verify AWS Deployment
```bash
# 1. Connect via SSH
ssh -i ~/.ssh/psono-lab ubuntu@<IP>

# 2. Check containers
docker-compose -f /opt/psono/docker/docker-compose.yml ps

# 3. View bootstrap logs
cat /var/log/psono-bootstrap.log

# 4. Run health check
/usr/local/bin/psono-health-check

# 5. Access Psono
# Browser: http://<IP>
# User: admin
# Password: <from terraform.tfvars>
```

#### Manage Terraform Stack
```bash
# View current state
terraform state list
terraform state show aws_instance.psono_server

# Update configuration
nano terraform.tfvars
terraform plan
terraform apply

# Scale resources
# Change instance_type = "t3.medium" in terraform.tfvars
terraform apply

# Stop but keep everything
aws ec2 stop-instances --instance-ids i-xxxxx

# Resume
aws ec2 start-instances --instance-ids i-xxxxx

# Destroy everything ⚠️
terraform destroy
```

---

## 🔍 Troubleshooting

### Docker Issues

**Containers not starting:**
```bash
docker-compose logs psono
docker-compose ps
docker inspect psono  # Detailed container info
```

**Port already in use:**
```bash
sudo lsof -i :80  # Find what's using port 80
docker-compose up -d --port 8080:80  # Use different port
```

**Database connection error:**
```bash
docker-compose restart postgres
sleep 10
docker-compose logs postgres
```

### Terraform Issues

**AWS credentials not found:**
```bash
aws configure
aws sts get-caller-identity
```

**Terraform init fails:**
```bash
rm -rf .terraform .terraform.lock.hcl
terraform init
```

**Instance not reaching desired state:**
```bash
# Check bootstrap logs
aws logs tail /psono/lab/deployment --follow

# Or SSH to instance
ssh -i ~/.ssh/psono-lab ubuntu@IP tail -f /var/log/psono-bootstrap.log
```

**Psono not accessible after deployment:**
```bash
# 1. Verify instance is running
aws ec2 describe-instances --instance-ids i-xxx | grep State

# 2. Check security group
aws ec2 describe-security-groups --group-ids sg-xxx | grep IpPermissions

# 3. SSH and test locally
ssh -i ~/.ssh/psono-lab ubuntu@IP
curl -s http://localhost | head

# 4. Check container health
docker ps
docker logs psono
```

---

## 🛠️ Using Makefile

```bash
# View all available commands
make help

# Docker operations
make docker-up              # Start containers
make docker-logs            # View logs
make docker-ps              # Container status
make docker-health          # Health check
make docker-clean           # Remove everything

# Terraform operations
make terraform-init         # Initialize
make terraform-validate     # Check syntax
make terraform-plan         # Preview
make terraform-apply        # Deploy
make terraform-destroy      # Cleanup

# Project operations
make lint                   # Validate configs
make status                 # Project overview
make clean                  # Remove temp files
```

---

## 📊 Cost Estimation

### Lab Configuration (Phase 2)
```
EC2 t3.small (on-demand):    ~$14/month
EBS Storage (30 GB):         ~$1/month
Data transfer out:           ~$1/month
Elastic IP (static):         $0 (free if in use)
CloudWatch logs:             <$1/month
────────────────────────────────────
TOTAL:                       ~$15-20/month
```

### Production Configuration (Phase 3+)
```
EC2 t3.medium:               ~$30/month
RDS PostgreSQL (db.t3.micro): ~$35/month
ALB:                         ~$20/month
NAT Gateway:                 ~$32/month
CloudWatch + monitoring:     ~$5/month
Data transfer + backup:      ~$10/month
────────────────────────────────────
TOTAL:                       ~$130-150/month
```

---

## 🔐 Security Checklist

### Phase 1 (Local Lab)
- [ ] Use strong passwords (12+ chars, mixed case, numbers)
- [ ] Don't commit .env file to Git
- [ ] Restrict SSH to your IP only
- [ ] Enable container health checks

### Phase 2 (AWS Lab)
- [ ] Set `allowed_ssh_cidrs = ["YOUR_IP/32"]` (not 0.0.0.0/0)
- [ ] Use Elastic IP for stable public IP
- [ ] Enable CloudWatch monitoring
- [ ] Review Security Group rules
- [ ] Change admin password on first login
- [ ] Regular CloudWatch log review

### Phase 3 (Production)
- [ ] Implement HTTPS with ACM certificates
- [ ] Use private subnets + NAT Gateway
- [ ] Enable VPC Flow Logs
- [ ] Implement RDS for database (managed backup)
- [ ] Use AWS Secrets Manager for credentials
- [ ] Enable CloudTrail for audit logs
- [ ] Implement auto-scaling
- [ ] Set up backup policies
- [ ] Configure KMS encryption
- [ ] Use VPN for admin access

---

## 📚 Documentation Map

| Document | Purpose | Audience |
|----------|---------|----------|
| [README.md](README.md) | Project overview | Everyone |
| [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) | Phase 1 (Docker) detailed guide | DevOps/SRE |
| [docs/TERRAFORM.md](docs/TERRAFORM.md) | Phase 2 (Terraform) detailed guide | DevOps/Cloud engineers |
| [terraform/README.md](terraform/README.md) | Quick Terraform reference | Terraform users |
| [tracker.md](tracker.md) | Execution checklist | Project managers |

---

## ✅ Success Criteria

### Phase 1 Complete When:
- [ ] Docker Compose stack starts without errors
- [ ] All containers show "Up" status
- [ ] Psono web UI accessible at http://localhost
- [ ] Can login with admin credentials
- [ ] Can create test secrets
- [ ] Data persists after container restart
- [ ] Health check script runs without errors

### Phase 2 Complete When:
- [ ] terraform init succeeds
- [ ] terraform validate passes
- [ ] terraform apply completes in <5 minutes
- [ ] EC2 instance is in "running" state
- [ ] Psono accessible at provided URL
- [ ] Can SSH to instance with provided command
- [ ] CloudWatch logs show successful deployment
- [ ] Can login and create secrets on AWS instance

---

## 🎯 Common Workflows

### Update Psono without downtime
```bash
cd docker
git pull origin main
docker-compose pull psono
docker-compose up -d psono
```

### Backup Psono data
```bash
# Local
docker-compose exec postgres pg_dump -U psono psono > backup_$(date +%Y%m%d).sql

# AWS (manual via snapshot)
aws ec2 create-snapshot --volume-id vol-xxx --description "Psono backup $(date)"
```

### Access Psono database
```bash
# Local
docker-compose exec postgres psql -U psono -d psono
SELECT * FROM auth_user;

# AWS
ssh -i ~/.ssh/psono-lab ubuntu@IP
docker-compose -f /opt/psono/docker/docker-compose.yml exec postgres psql -U psono -d psono
```

### Monitor resources
```bash
# Local
docker stats

# AWS
aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name CPUUtilization --dimensions Name=InstanceId,Value=i-xxx --start-time 2026-01-20T00:00:00Z --end-time 2026-01-20T23:59:59Z --period 3600 --statistics Average
```

---

## 🚀 Next Steps

After successful Phase 1 & 2 deployment:

1. **Document Your Setup**
   - Screenshot Psono dashboard
   - Note terraform outputs
   - Document any customizations

2. **Plan Phase 3**
   - Design VPC architecture
   - Plan HTTPS/TLS strategy
   - Design RDS migration plan

3. **Team Onboarding**
   - Share access credentials securely
   - Train on Psono usage
   - Document backup procedures

4. **Monitoring & Maintenance**
   - Set up CloudWatch alarms
   - Plan update strategy
   - Schedule backup verification

---

**Last Updated:** 20 de janeiro de 2026  
**Status:** Phases 1 & 2 Ready for Production Use  
**Version:** 1.0 (Lab)
