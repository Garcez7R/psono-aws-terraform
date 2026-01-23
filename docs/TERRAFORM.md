# Psono Terraform Deployment Guide – Phase 2

## Overview

Phase 2 transforms the manual local setup into **Infrastructure as Code** using Terraform, enabling reproducible, automated AWS deployments.

**Objectives:**
- Define AWS infrastructure declaratively (EC2, VPC, Security Groups, IAM)
- Automate EC2 bootstrap with user-data script
- Implement least privilege access controls
- Enable CloudWatch monitoring
- Generate deployment outputs (IPs, URLs, SSH commands)

**Duration:** ~10 minutes (after AWS credentials configured)

**Status:** `terraform apply` → fully functional Psono in AWS in ~5-10 minutes

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│              AWS Account (us-east-1)            │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌─────────────────────────────────────────┐  │
│  │  Default VPC                            │  │
│  │  ┌───────────────────────────────────┐  │  │
│  │  │  Default Subnet (Availability Zone)  │  │
│  │  │  ┌─────────────────────────────┐  │  │  │
│  │  │  │  EC2 Instance               │  │  │  │
│  │  │  │  (Ubuntu 22.04 LTS)         │  │  │  │
│  │  │  │  ┌───────────────────────┐  │  │  │  │
│  │  │  │  │ Docker Compose        │  │  │  │  │
│  │  │  │  │ - nginx               │  │  │  │  │
│  │  │  │  │ - psono               │  │  │  │  │
│  │  │  │  │ - postgres            │  │  │  │  │
│  │  │  │  └───────────────────────┘  │  │  │  │
│  │  │  │  IAM Role: psono-ec2-role   │  │  │  │
│  │  │  │  Root: gp3 (30 GB)          │  │  │  │
│  │  │  └─────────────────────────────┘  │  │  │
│  │  │                                    │  │  │
│  │  │  Security Group: psono-sg         │  │  │
│  │  │  - SSH (22): Restricted          │  │  │
│  │  │  - HTTP (80): Open               │  │  │
│  │  │  - Egress: All                   │  │  │
│  │  └───────────────────────────────────┘  │  │
│  │  Elastic IP: <static-public-ip>         │  │
│  └─────────────────────────────────────────┘  │
│                                                 │
│  CloudWatch Logs: /psono/lab/deployment       │
│  CloudWatch Alarms: Status check, CPU          │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## Prerequisites

### AWS Setup
- AWS account with billing enabled
- AWS IAM user with permissions for EC2, VPC, IAM, CloudWatch
- AWS credentials configured locally:

```bash
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-east-1), Output (json)

# Verify
aws sts get-caller-identity
```

### Tools Installation

**Linux/Mac:**
```bash
# Install Terraform
brew install terraform  # Mac with Homebrew

# Or Linux (Ubuntu/Debian):
wget https://apt.releases.hashicorp.com/gpg
sudo apt-key add gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update
sudo apt-get install -y terraform

# Verify
terraform version
# Expected: Terraform v1.0+
```

**Windows (WSL/WSL2):**
```bash
# Follow Linux instructions above in WSL terminal
```

### SSH Key Pair

**Option A: Create new key pair**
```bash
# Generate SSH key
ssh-keygen -t ed25519 -f ~/.ssh/psono-lab -C "psono-lab" -N ""

# Or RSA (for older systems)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/psono-lab -C "psono-lab" -N ""

# Verify
ls -la ~/.ssh/psono-lab*
```

**Option B: Use existing key pair**
```bash
# Ensure you have the private key with restricted permissions
chmod 600 ~/.ssh/your-existing-key.pem
```

---

## Step 1: Prepare Terraform Configuration

### 1.1 Clone Repository
```bash
git clone <your-repo-url> psono-aws
cd psono-aws/terraform
```

### 1.2 Verify Files
```bash
ls -la
# Expected:
# main.tf
# variables.tf
# security.tf
# outputs.tf
# user-data.sh
# terraform.tfvars.example
```

### 1.3 Initialize Terraform
```bash
terraform init
# Downloads AWS provider plugin (~80 MB)
```

### 1.4 Validate Configuration
```bash
terraform validate
# Expected: Success! The configuration is valid.
```

---

## Step 2: Configure Variables

### 2.1 Copy Template
```bash
cp terraform.tfvars.example terraform.tfvars
```

### 2.2 Edit Configuration
```bash
nano terraform.tfvars
```

**Critical settings to customize:**

```hcl
# Your GitHub repository URL
repository_url = "https://github.com/YOUR_USERNAME/PsOno.git"

# AWS region
aws_region = "us-east-1"

# Instance type (t3.small for lab, ~$0.02/hour)
instance_type = "t3.small"

# Admin credentials (MUST change on first login!)
psono_admin_password = "SecurePassword@123456"

# Database password
db_password = "PgPassword@123456"

# Django secret key (generate via Python)
secret_key = "your-secret-key-min-32-chars"

# SSH access (⚠️ restrict in production)
allowed_ssh_cidrs = ["YOUR_IP/32"]  # Replace YOUR_IP

# Optional: Elastic IP for static IP
use_elastic_ip = true
```

**Generate SECRET_KEY:**
```bash
python3 -c "import secrets; print(secrets.token_urlsafe(50))"
```

### 2.3 Security Best Practices

**⚠️ DO NOT commit .tfvars to Git:**
```bash
# Already in .gitignore, but verify
echo "terraform.tfvars" >> .gitignore
git add .gitignore && git commit -m "Ensure terraform.tfvars is ignored"
```

**Restrict SSH access (production):**
```hcl
# Find your IP
curl -s https://checkip.amazonaws.com

# In terraform.tfvars
allowed_ssh_cidrs = ["203.0.113.123/32"]  # Your IP only
```

---

## Step 3: Plan Deployment

### 3.1 Run Terraform Plan
```bash
terraform plan -out=tfplan
# Shows all resources to be created
# Expected: 1 to create
```

### 3.2 Review Plan Output
```
# Look for:
✓ EC2 instance (t3.small)
✓ Security Group (psono-sg)
✓ IAM Role (psono-ec2-role)
✓ IAM Instance Profile
✓ CloudWatch Log Group
✓ CloudWatch Alarms
✓ Elastic IP (if enabled)
✓ AMI (Ubuntu 22.04 LTS latest)
```

### 3.3 Check Estimated Costs

**Expected Monthly Cost (Lab):**
- EC2 t3.small on-demand: ~$14
- Elastic IP (if idle): $0
- Data transfer: ~$1
- **Total: ~$15-20/month**

---

## Step 4: Apply Infrastructure

### 4.1 Deploy to AWS
```bash
terraform apply tfplan
# Or without plan file:
terraform apply

# Type "yes" to confirm
```

### 4.2 Monitor Progress
```bash
# In another terminal, watch logs:
tail -f /tmp/terraform.log

# Or monitor in AWS Console:
# EC2 > Instances > psono-server-lab
# Status Checks: Running → OK (takes ~2 min)
```

### 4.3 Wait for Bootstrap
```
Expected timeline:
0:00 - EC2 instance starts
0:30 - System updates complete
1:00 - Docker installed
2:00 - Docker Compose stack starts
3:00 - PostgreSQL initialized
4:00 - Psono fully initialized
5:00 - Health checks pass ✓
```

---

## Step 5: Retrieve Outputs

### 5.1 Display Outputs
```bash
terraform output

# Or specific output:
terraform output psono_web_url
terraform output ssh_connection_command
```

### 5.2 Key Information Returned

```
Outputs:

instance_id = "i-0123456789abcdef0"
instance_public_ip = "203.0.113.100"
elastic_ip = "203.0.113.101" (if allocated)
psono_web_url = "http://203.0.113.101"
ssh_connection_command = "ssh -i ~/.ssh/psono-lab ubuntu@203.0.113.101"
security_group_id = "sg-0123456789abcdef0"
cloudwatch_log_group = "/psono/lab/deployment"
```

### 5.3 Save for Later Reference
```bash
terraform output -json > outputs.json
# Safe to commit this file (IPs are not secrets)
```

---

## Step 6: Verify Deployment

### 6.1 Connect via SSH
```bash
# Use the SSH command from terraform output
ssh -i ~/.ssh/psono-lab ubuntu@203.0.113.101

# Or shorter (if added to ~/.ssh/config)
ssh psono-lab
```

### 6.2 Check Container Status
```bash
# In the EC2 instance:
cd /opt/psono/docker
docker-compose ps

# Expected all "Up" and "healthy"
```

### 6.3 View Bootstrap Logs
```bash
# In the EC2 instance:
tail -f /var/log/psono-bootstrap.log

# Or all logs:
journalctl -u cloud-final -f
```

### 6.4 Access Psono Web UI
```
Browser: http://203.0.113.101
(or use the URL from terraform output)

Login:
- Username: admin
- Password: <PSONO_ADMIN_PASSWORD from terraform.tfvars>

⚠️ MUST change password on first login!
```

### 6.5 Run Health Check
```bash
# In the EC2 instance:
/usr/local/bin/psono-health-check

# Shows: running containers, resource usage, database stats
```

---

## Terraform State Management

### State File Security

```bash
# State file contains sensitive data!
# Default location: terraform.tfstate (LOCAL)

# Protect it:
chmod 600 terraform.tfstate
echo "terraform.tfstate*" >> .gitignore
git add .gitignore && git commit -m "Protect Terraform state"
```

### Remote State (Phase 3+)

For team environments, use S3 + DynamoDB:

```hcl
# In main.tf (uncomment and configure):
backend "s3" {
  bucket         = "psono-terraform-state-bucket"
  key            = "prod/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-locks"
}
```

---

## Common Operations

### Destroy Infrastructure (⚠️ Deletes everything)

```bash
# Review what will be destroyed
terraform plan -destroy

# Delete all resources
terraform destroy

# Type "yes" to confirm
# Expected time: 2-3 minutes
```

### Update Configuration

```bash
# Edit terraform.tfvars
nano terraform.tfvars

# Plan changes
terraform plan

# Apply changes
terraform apply
```

### Scale Resources

```hcl
# In terraform.tfvars, change:
instance_type = "t3.medium"      # More resources
root_volume_size = 50            # Larger disk

# Apply:
terraform apply
```

### Add SSH Key to Instance

```bash
# Generate if not already done
ssh-keygen -t ed25519 -f ~/.ssh/psono-lab

# Add public key to EC2 (via AWS Console or terraform)
# Or use:
aws ec2-instance-connect send-ssh-public-key \
  --instance-id i-0123456789 \
  --os-user ubuntu \
  --ssh-public-key file://~/.ssh/psono-lab.pub
```

---

## Troubleshooting

### "Access Denied" or "Not Authorized"

```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify IAM permissions for EC2, VPC, IAM, CloudWatch
# Missing permissions:
# - ec2:RunInstances
# - ec2:DescribeInstances
# - iam:CreateRole, iam:PassRole
# - logs:CreateLogGroup
```

### "Invalid AMI" Error

```bash
# Ubuntu AMI may not be available in your region
# In terraform.tfvars, try a different region:
aws_region = "us-west-2"
```

### "Subnet not found"

```bash
# Default VPC may not exist in your account
# Create default VPC via AWS Console:
# EC2 > VPC > Actions > Create default VPC

# Or use Terraform to create custom VPC (Phase 3)
```

### Instance stuck in "initializing"

```bash
# Wait 5-10 minutes for bootstrap script
# Check CloudWatch logs:
aws logs tail /psono/lab/deployment --follow

# SSH to instance and check manually:
ssh -i ~/.ssh/psono-lab ubuntu@IP
cat /var/log/psono-bootstrap.log
```

### Psono not accessible after `terraform apply`

```bash
# 1. Verify instance is running
aws ec2 describe-instances --instance-ids i-xxx | grep State

# 2. Check security group
aws ec2 describe-security-groups --group-ids sg-xxx

# 3. Check bootstrap logs
ssh -i ~/.ssh/psono-lab ubuntu@IP tail -f /var/log/psono-bootstrap.log

# 4. Verify containers
ssh -i ~/.ssh/psono-lab ubuntu@IP 'docker ps'

# 5. Test local connectivity
ssh -i ~/.ssh/psono-lab ubuntu@IP 'curl -s http://localhost | head -20'
```

### High costs or unexpected charges

```bash
# Destroy unused resources
terraform destroy

# Or stop instance temporarily
aws ec2 stop-instances --instance-ids i-xxx

# Resume
aws ec2 start-instances --instance-ids i-xxx
```

---

## Security Best Practices – Phase 2

✅ **Implemented:**
- EC2 security groups restrict SSH and HTTP
- IAM role with minimal permissions
- CloudWatch monitoring and alarms
- No hardcoded credentials in code
- SSH key-based authentication only
- Encryption at rest for EBS

❌ **Not yet (Phase 3+):**
- HTTPS/TLS
- Private subnet + NAT gateway
- VPC endpoint
- KMS encryption
- Secrets Manager for credentials

---

## Next Steps

After Phase 2 validation:

### Immediate
- [ ] Document IP addresses and SSH commands
- [ ] Test container updates via Docker Compose
- [ ] Verify backup procedures
- [ ] Create IAM user for team access

### Phase 3 (Production)
- [ ] Add HTTPS/TLS (AWS ACM)
- [ ] Implement VPC with private subnets
- [ ] Use RDS for PostgreSQL (managed database)
- [ ] Add Application Load Balancer
- [ ] Implement CloudFormation/Terraform modules for reusability
- [ ] Set up remote Terraform state (S3 + DynamoDB)

---

## Useful Commands

```bash
# Plan without applying
terraform plan

# Apply with auto-approval (caution!)
terraform apply -auto-approve

# Destroy specific resource
terraform destroy -target aws_instance.psono_server

# Format code
terraform fmt -recursive

# Validate syntax
terraform validate

# Show current state
terraform show

# Remove resource from state (without destroying)
terraform state rm aws_instance.psono_server

# List resources
terraform state list

# Get specific output
terraform output instance_public_ip

# Refresh state
terraform refresh

# Lock state file during operations
terraform force-unlock <LOCK_ID>
```

---

## References

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform.io/language/state/best-practices)
- [AWS EC2 User Data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)
- [AWS Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

---

**Last Updated:** 20 de janeiro de 2026  
**Status:** Phase 2 Documentation Complete  
**Next:** Phase 3 – Production-Ready Deployment

---

## Quick Reference: From Git to Live

```bash
# 1. Clone and configure
git clone <repo> && cd psono-aws/terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # customize

# 2. Validate and plan
terraform init
terraform validate
terraform plan

# 3. Deploy
terraform apply

# 4. Get URLs
terraform output

# 5. Access Psono
# Browser: http://<IP from output>
# SSH: ssh -i ~/.ssh/key ubuntu@<IP>

# 6. Cleanup (when done)
terraform destroy
```
