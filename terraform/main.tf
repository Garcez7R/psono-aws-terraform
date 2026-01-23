terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure for remote state (Phase 3+)
  # backend "s3" {
  #   bucket         = "psono-terraform-state"
  #   key            = "prod/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Psono-Lab"
      Environment = var.environment
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    }
  }
}

# Data source for Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# EC2 Instance
resource "aws_instance" "psono_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  # Network
  subnet_id                   = data.aws_subnet.default.id
  vpc_security_group_ids      = [aws_security_group.psono.id]
  associate_public_ip_address = true
  private_ip                  = var.private_ip

  # IAM Role for EC2
  iam_instance_profile = aws_iam_instance_profile.psono.name

  # Storage
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  # User data for bootstrap
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    repository_url   = var.repository_url
    docker_user      = var.docker_user
    docker_password  = var.docker_password
    psono_admin_user = var.psono_admin_username
    psono_admin_pass = var.psono_admin_password
    db_password      = var.db_password
    secret_key       = var.secret_key
  }))

  # Monitoring
  monitoring = true

  tags = {
    Name = "psono-server-${var.environment}"
  }

  lifecycle {
    ignore_changes = [ami]
  }

  depends_on = [
    aws_security_group.psono
  ]
}

# Elastic IP for static access (optional)
resource "aws_eip" "psono" {
  count    = var.use_elastic_ip ? 1 : 0
  instance = aws_instance.psono_server.id
  domain   = "vpc"

  tags = {
    Name = "psono-eip-${var.environment}"
  }

  depends_on = [aws_instance.psono_server]
}

# Data source for default VPC
data "aws_vpc" "default" {
  default = true
}

# Data source for default subnet in selected AZ
data "aws_subnet" "default" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "${var.aws_region}${var.availability_zone}"
  default_for_az    = true
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "instance_status" {
  alarm_name          = "psono-instance-status-check-${var.environment}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Alert when EC2 instance status check fails"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.psono_server.id
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name          = "psono-high-cpu-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alert when CPU utilization is high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.psono_server.id
  }
}
