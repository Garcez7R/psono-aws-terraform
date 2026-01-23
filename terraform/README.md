# Psono Terraform

This directory contains the **Terraform configuration** for deploying Psono on AWS (Phase 2).

## Quick Start

```bash
# 1. Configure AWS credentials
aws configure

# 2. Copy and customize variables
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars

# 3. Initialize Terraform
terraform init

# 4. Plan deployment
terraform plan

# 5. Deploy to AWS
terraform apply

# 6. Get outputs
terraform output

# 7. Access Psono
# URL and SSH command will be in outputs
```

## Files

| File | Purpose |
|------|---------|
| `main.tf` | EC2 instance, VPC, monitoring, CloudWatch alarms |
| `variables.tf` | Input variables with validation |
| `security.tf` | Security Groups, IAM Role, IAM Policy |
| `outputs.tf` | Deployment outputs (IPs, URLs, SSH commands) |
| `user-data.sh` | EC2 bootstrap script (install Docker, deploy Psono) |
| `terraform.tfvars.example` | Configuration template (copy to `terraform.tfvars`) |
| `terraform.tfstate` | State file (⚠️ keep secure, don't commit) |

## Requirements

- Terraform 1.0+
- AWS CLI v2
- AWS Account with credentials configured
- SSH key pair (generate or use existing)

## Configuration

Copy `terraform.tfvars.example` to `terraform.tfvars` and customize:

```hcl
aws_region               = "us-east-1"
instance_type            = "t3.small"
repository_url           = "https://github.com/YOUR_USERNAME/PsOno.git"
psono_admin_password     = "ChangeMe@Lab123456"
db_password              = "PgPass@Lab123456"
secret_key               = "your-secret-key-here"
allowed_ssh_cidrs        = ["YOUR_IP/32"]  # Restrict SSH access
```

## Deployment

```bash
# Validate configuration
terraform validate

# Preview changes
terraform plan

# Deploy infrastructure
terraform apply

# Get connection details
terraform output
```

## Access

After `terraform apply`:

```bash
# Get Psono URL
terraform output psono_web_url

# Get SSH command
terraform output ssh_connection_command

# Connect via SSH
ssh -i ~/.ssh/psono-lab ubuntu@<IP>

# Check container status
docker-compose -f /opt/psono/docker/docker-compose.yml ps
```

## Cleanup

```bash
# Destroy all resources
terraform destroy

# Or specific resource
terraform destroy -target aws_instance.psono_server
```

## Costs

**Lab Configuration (t3.small):**
- EC2: ~$14/month
- Storage: ~$1/month
- Data transfer: ~$1/month
- **Total: ~$15-20/month**

## Security Notes

- ⚠️ SSH access defaults to `0.0.0.0/0` (world open) → restrict in production
- ⚠️ Credentials in `.tfvars` → don't commit, use `.gitignore`
- ✅ IAM role with least privilege access
- ✅ EC2 monitoring enabled (CloudWatch)
- ✅ SSH key-based authentication only
- ❌ No HTTPS (Phase 3+)
- ❌ No private subnet (Phase 3+)

## Documentation

- [Phase 2: Terraform Deployment Guide](../docs/TERRAFORM.md)
- [General README](../README.md)
- [Deployment Guide](../docs/DEPLOYMENT.md)

## Troubleshooting

### "terraform init" fails
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Clear Terraform cache
rm -rf .terraform .terraform.lock.hcl
terraform init
```

### "Instance startup failed"
```bash
# Check bootstrap logs
aws logs tail /psono/lab/deployment --follow

# Or SSH to instance
ssh -i ~/.ssh/key ubuntu@IP tail -f /var/log/psono-bootstrap.log
```

### "Psono not accessible"
```bash
# Verify instance status
aws ec2 describe-instances --instance-ids i-xxx | grep State

# Check security group
aws ec2 describe-security-groups --group-ids sg-xxx

# Test local connectivity
ssh -i ~/.ssh/key ubuntu@IP curl http://localhost
```

## License

Terraform code: MIT  
Psono Server: AGPL v3

---

**Last Updated:** 20 de janeiro de 2026
