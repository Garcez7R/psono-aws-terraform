resource "aws_security_group" "psono" {
  name        = "psono-sg-${var.environment}"
  description = "Security group for Psono Server - Lab/Production"
  vpc_id      = data.aws_vpc.default.id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "psono-sg-${var.environment}"
  }
}

# Allow SSH (key-based authentication only)
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.psono.id

  description = "SSH access from allowed CIDR blocks"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
  cidr_ipv4   = var.allowed_ssh_cidrs[0]

  tags = {
    Name = "ssh-ingress"
  }
}

# Additional SSH rules for additional CIDRs (if more than one)
resource "aws_vpc_security_group_ingress_rule" "ssh_extra" {
  count             = length(var.allowed_ssh_cidrs) > 1 ? length(var.allowed_ssh_cidrs) - 1 : 0
  security_group_id = aws_security_group.psono.id

  description = "SSH access from additional CIDR block"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
  cidr_ipv4   = var.allowed_ssh_cidrs[count.index + 1]

  tags = {
    Name = "ssh-ingress-${count.index + 1}"
  }
}

# Allow HTTP (for Psono web UI)
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.psono.id

  description = "HTTP access for Psono web UI"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  cidr_ipv4   = var.allowed_http_cidrs[0]

  tags = {
    Name = "http-ingress"
  }
}

# Additional HTTP rules (if more than one CIDR)
resource "aws_vpc_security_group_ingress_rule" "http_extra" {
  count             = length(var.allowed_http_cidrs) > 1 ? length(var.allowed_http_cidrs) - 1 : 0
  security_group_id = aws_security_group.psono.id

  description = "HTTP access from additional CIDR block"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  cidr_ipv4   = var.allowed_http_cidrs[count.index + 1]

  tags = {
    Name = "http-ingress-${count.index + 1}"
  }
}

# Reserved for HTTPS (Phase 3+)
# resource "aws_vpc_security_group_ingress_rule" "https" {
#   security_group_id = aws_security_group.psono.id
#   description       = "HTTPS access (Phase 3+)"
#   from_port         = 443
#   to_port           = 443
#   ip_protocol       = "tcp"
#   cidr_ipv4         = "0.0.0.0/0"
# }

# Allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.psono.id

  description      = "Allow all outbound traffic"
  ip_protocol      = "-1"
  cidr_ipv4        = "0.0.0.0/0"

  tags = {
    Name = "allow-all-egress"
  }
}

# IAM Role for EC2 instance
resource "aws_iam_role" "psono_role" {
  name = "psono-ec2-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "psono-role-${var.environment}"
  }
}

# IAM Policy for minimal permissions
resource "aws_iam_role_policy" "psono_policy" {
  name = "psono-ec2-policy-${var.environment}"
  role = aws_iam_role.psono_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/psono/*"
      },
      {
        Sid    = "EC2DescribeInstances"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchMetrics"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "Psono"
          }
        }
      },
      {
        Sid    = "DenyDangerousActions"
        Effect = "Deny"
        Action = [
          "ec2:TerminateInstances",
          "ec2:DeleteVolume",
          "iam:DeleteUser",
          "iam:DeleteRole"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "psono" {
  name = "psono-instance-profile-${var.environment}"
  role = aws_iam_role.psono_role.name
}

# CloudWatch Log Group for Psono
resource "aws_cloudwatch_log_group" "psono" {
  name              = "/psono/${var.environment}/deployment"
  retention_in_days = 30

  tags = {
    Name = "psono-logs-${var.environment}"
  }
}
