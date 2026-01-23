output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.psono_server.id
}

output "instance_public_ip" {
  description = "Public IP address of EC2 instance"
  value       = aws_instance.psono_server.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of EC2 instance"
  value       = aws_instance.psono_server.private_ip
}

output "instance_public_dns" {
  description = "Public DNS name of EC2 instance"
  value       = aws_instance.psono_server.public_dns
}

output "elastic_ip" {
  description = "Elastic IP address (if allocated)"
  value       = var.use_elastic_ip ? aws_eip.psono[0].public_ip : null
}

output "elastic_ip_allocation_id" {
  description = "Elastic IP allocation ID (if allocated)"
  value       = var.use_elastic_ip ? aws_eip.psono[0].id : null
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.psono.id
}

output "security_group_name" {
  description = "Security Group name"
  value       = aws_security_group.psono.name
}

output "iam_role_arn" {
  description = "IAM Role ARN"
  value       = aws_iam_role.psono_role.arn
}

output "iam_instance_profile" {
  description = "IAM Instance Profile name"
  value       = aws_iam_instance_profile.psono.name
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group name"
  value       = aws_cloudwatch_log_group.psono.name
}

output "psono_web_url" {
  description = "URL to access Psono web UI"
  value       = var.use_elastic_ip ? "http://${aws_eip.psono[0].public_ip}" : "http://${aws_instance.psono_server.public_ip}"
}

output "ssh_connection_command" {
  description = "SSH command to connect to instance"
  value       = var.use_elastic_ip ? "ssh -i /path/to/key.pem ubuntu@${aws_eip.psono[0].public_ip}" : "ssh -i /path/to/key.pem ubuntu@${aws_instance.psono_server.public_ip}"
}

output "ami_id" {
  description = "AMI ID used for instance"
  value       = data.aws_ami.ubuntu.id
}

output "ami_name" {
  description = "AMI name (Ubuntu version)"
  value       = data.aws_ami.ubuntu.name
}

output "instance_state" {
  description = "Current instance state"
  value       = aws_instance.psono_server.instance_state
}

output "subnet_id" {
  description = "Subnet ID where instance is deployed"
  value       = aws_instance.psono_server.subnet_id
}

output "vpc_id" {
  description = "VPC ID"
  value       = data.aws_vpc.default.id
}

output "availability_zone" {
  description = "Availability Zone of the instance"
  value       = aws_instance.psono_server.availability_zone
}

output "terraform_outputs_summary" {
  description = "Summary of all important outputs"
  value = {
    instance_id        = aws_instance.psono_server.id
    public_ip          = aws_instance.psono_server.public_ip
    elastic_ip         = var.use_elastic_ip ? aws_eip.psono[0].public_ip : "Not allocated"
    psono_url          = var.use_elastic_ip ? "http://${aws_eip.psono[0].public_ip}" : "http://${aws_instance.psono_server.public_ip}"
    ssh_command        = var.use_elastic_ip ? "ssh -i /path/to/key.pem ubuntu@${aws_eip.psono[0].public_ip}" : "ssh -i /path/to/key.pem ubuntu@${aws_instance.psono_server.public_ip}"
    security_group     = aws_security_group.psono.name
    cloudwatch_logs    = aws_cloudwatch_log_group.psono.name
    next_step          = "1. Replace /path/to/key.pem with your actual SSH key path"
  }
}
