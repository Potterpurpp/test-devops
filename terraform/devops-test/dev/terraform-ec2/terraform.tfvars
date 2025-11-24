# Project Configuration
project_name = "devops-test"
environment  = "dev"
region       = "ap-southeast-1"

# VPC and Networking: leave `vpc_id` and `subnet_id` unset to auto-discover the VPC/subnet
# vpc_id and subnet_id are optional and will be discovered by `terraform` when omitted

# EC2 Instance Configuration
ec2_instance_name = "devops-test-dev-ec2"
ec2_instance_type = "t3.micro"  # Small instance for dev environment

# Security Group Configuration
ec2_create_security_group = true
ec2_security_group_name   = "devops-test-dev-sg"

# Ingress Rules - Allow SSH and HTTP for dev environment
ec2_ingress_rules = [
  {
    description      = "SSH access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]  # Update with your IP for better security
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  },
  {
    description      = "HTTP access"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  },
  {
    description      = "StatsD port"
    from_port        = 8125
    to_port          = 8125
    protocol         = "udp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }
]

# Key Pair Configuration (Update with your public key)
ec2_create_key_pair = false
ec2_existing_key_pair_name = "your-key-pair-name"  # Replace with your existing key pair

# IAM Configuration
ec2_create_iam_role = true
ec2_iam_policy_arns = [
  "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
]

# CloudWatch Configuration
ec2_cloudwatch_log_group_retention_in_days = 7  # 7 days for dev

# Tags
tags = {
  Team        = "DevOps"
  ManagedBy   = "Terraform"
  CostCenter  = "Engineering"
}

# Application / ECR settings (the deployment will use ECR module outputs when available)
ec2_git_repo = "https://github.com/Potterpurpp/test-devops.git"
ec2_image_name = "test-devops-app"
ec2_image_tag = "dev-latest"
