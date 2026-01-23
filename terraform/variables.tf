variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d{1}$", var.aws_region))
    error_message = "AWS region must be a valid region format (e.g., us-east-1)"
  }
}

variable "availability_zone" {
  description = "Availability zone suffix (a, b, c)"
  type        = string
  default     = "a"

  validation {
    condition     = contains(["a", "b", "c", "d"], var.availability_zone)
    error_message = "Availability zone must be a, b, c, or d"
  }
}

variable "environment" {
  description = "Environment name (lab, staging, prod)"
  type        = string
  default     = "lab"

  validation {
    condition     = contains(["lab", "staging", "prod"], var.environment)
    error_message = "Environment must be lab, staging, or prod"
  }
}

variable "instance_type" {
  description = "EC2 instance type (t3.micro for lab, t3.small+ for production)"
  type        = string
  default     = "t3.small"

  validation {
    condition     = can(regex("^[a-z][0-9][a-z]?\\.[a-z]+$", var.instance_type))
    error_message = "Instance type must be a valid AWS instance type"
  }
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 20 && var.root_volume_size <= 500
    error_message = "Root volume size must be between 20 and 500 GB"
  }
}

variable "private_ip" {
  description = "Private IP address for EC2 instance (optional, auto-assigned if not specified)"
  type        = string
  default     = null
}

variable "use_elastic_ip" {
  description = "Whether to allocate an Elastic IP for static IP"
  type        = bool
  default     = true
}

variable "repository_url" {
  description = "Git repository URL for Psono project"
  type        = string
  
  validation {
    condition     = can(regex("^https://github\\.com/.*\\.git$", var.repository_url)) || can(regex("^git@github\\.com:.*\\.git$", var.repository_url))
    error_message = "Repository URL must be a valid GitHub HTTPS or SSH URL"
  }
}

variable "psono_admin_username" {
  description = "Initial Psono admin username"
  type        = string
  default     = "admin"
  sensitive   = true

  validation {
    condition     = length(var.psono_admin_username) >= 3 && length(var.psono_admin_username) <= 30
    error_message = "Admin username must be between 3 and 30 characters"
  }
}

variable "psono_admin_password" {
  description = "Initial Psono admin password (MUST be changed on first login!)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.psono_admin_password) >= 12
    error_message = "Admin password must be at least 12 characters for security"
  }
}

variable "db_password" {
  description = "PostgreSQL database password"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 12 && can(regex("[A-Z]", var.db_password)) && can(regex("[a-z]", var.db_password)) && can(regex("[0-9]", var.db_password))
    error_message = "DB password must be at least 12 chars, with uppercase, lowercase, and numbers"
  }
}

variable "secret_key" {
  description = "Django SECRET_KEY for Psono (generate via: python -c 'import secrets; print(secrets.token_urlsafe(50))')"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.secret_key) >= 32
    error_message = "SECRET_KEY must be at least 32 characters long"
  }
}

variable "docker_user" {
  description = "Docker Hub username (optional, for pulling private images)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "docker_password" {
  description = "Docker Hub password or personal access token (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"] # ⚠️ Restrict in production!

  validation {
    condition = alltrue([
      for cidr in var.allowed_ssh_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All SSH CIDR blocks must be valid CIDR notation"
  }
}

variable "allowed_http_cidrs" {
  description = "CIDR blocks allowed for HTTP access"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for cidr in var.allowed_http_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All HTTP CIDR blocks must be valid CIDR notation"
  }
}

variable "enable_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "enable_termination_protection" {
  description = "Enable termination protection to prevent accidental deletion"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default = {
    Terraform   = "true"
    Application = "Psono"
  }
}
