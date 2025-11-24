# Project Configuration
project_name = "devops-test"
environment  = "uat"
region       = "ap-southeast-1"

# VPC and Networking: leave `vpc_id` and `subnet_id` unset to auto-discover the VPC/subnet
# vpc_id and subnet_id are optional and will be discovered by `terraform` when omitted

# EC2 Instance Configuration
ec2_instance_name = "devops-test-uat-ec2"
ec2_instance_type = "t3.small"  # Slightly larger instance for UAT

# Security Group Configuration
ec2_create_security_group = true
ec2_security_group_name   = "devops-test-uat-sg"

# Ingress Rules - More restrictive for UAT environment
ec2_ingress_rules = [
  {
    description      = "SSH access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["10.11.0.0/16"]  # Update with your IP range
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
    cidr_blocks      = ["10.11.0.0/16"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  },
  {
    description      = "HTTPS access"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["10.11.0.0/16"]
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
    cidr_blocks      = ["10.11.0.0/16"]  # More restrictive - internal network only
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }
]

# Key Pair Configuration
ec2_create_key_pair = false

# IAM Configuration
ec2_create_iam_role = true
ec2_iam_policy_arns = [
  "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
  "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
]

# Root Block Device - Encrypted for test environment
ec2_root_block_device = {
  volume_type           = "gp3"
  volume_size           = 20
  iops                  = 3000
  throughput            = 125
  encrypted             = true
  kms_key_id            = null
  delete_on_termination = true
}

# CloudWatch Configuration
ec2_cloudwatch_log_group_retention_in_days = 14  # 14 days for test

# Tags
tags = {
  Team        = "DevOps"
  ManagedBy   = "Terraform"
  CostCenter  = "Engineering"
}

# Application / ECR settings (the deployment will use ECR module outputs when available)
ec2_git_repo = "https://github.com/Potterpurpp/test-devops.git"
ec2_image_name = "test-devops-app-uat"
ec2_image_tag = "latest"
ec2_ecr_registry_uat = "123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/test-devops-app-uat"
ec2_ecr_registry_prod = "123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/test-devops-app-prod"