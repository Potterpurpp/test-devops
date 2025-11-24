# Project Configuration
project_name = "devops-test"
environment  = "prod"
region       = "ap-southeast-1"

# VPC and Networking: leave `vpc_id` and `subnet_id` unset to auto-discover the VPC/subnet
# vpc_id and subnet_id are optional and will be discovered by `terraform` when omitted

# EC2 Instance Configuration
ec2_instance_name = "devops-test-prod-ec2"
ec2_instance_type = "t3.medium"  # Larger instance for production workload

# Networking Configuration
ec2_associate_public_ip_address = false  # No public IP for production (use NAT/ALB)

# Security Group Configuration
ec2_create_security_group = true
ec2_security_group_name   = "devops-test-prod-sg"

# Ingress Rules - Highly restrictive for production
ec2_ingress_rules = [
  {
    description      = "SSH access from bastion only"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["10.12.0.0/16"]  # Only from VPC CIDR
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  },
  {
    description      = "HTTP access from load balancer"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["10.12.0.0/16"]  # Only from VPC CIDR
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  },
  {
    description      = "HTTPS access from load balancer"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["10.12.0.0/16"]  # Only from VPC CIDR
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  },
  {
    description      = "StatsD port from internal network"
    from_port        = 8125
    to_port          = 8125
    protocol         = "udp"
    cidr_blocks      = ["10.12.0.0/16"]  # Only from VPC CIDR
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

# Root Block Device - Encrypted with KMS for production
ec2_root_block_device = {
  volume_type           = "gp3"
  volume_size           = 50
  iops                  = 3000
  throughput            = 125
  encrypted             = true
  kms_key_id            = null  # Replace with KMS key ARN for production
  delete_on_termination = false  # Keep volume on instance termination
}

# Metadata Options - Enhanced security for production
ec2_metadata_options = {
  http_endpoint               = "enabled"
  http_tokens                 = "required"  # IMDSv2 required
  http_put_response_hop_limit = 1
  instance_metadata_tags      = "disabled"
}

# CloudWatch Configuration
ec2_cloudwatch_log_group_retention_in_days = 90  # 90 days for production

# Elastic IP Configuration
ec2_create_eip = false  # Use load balancer instead

# Tags
tags = {
  Team        = "DevOps"
  ManagedBy   = "Terraform"
  CostCenter  = "Engineering"
  Backup      = "Daily"
  Compliance  = "Required"
}

# Application / ECR settings (the deployment will use ECR module outputs when available)
ec2_git_repo = "https://github.com/Potterpurpp/test-devops.git"
ec2_image_name = "test-devops-app-prod"
ec2_image_tag = "latest"
ec2_ecr_registry_prod = "123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/test-devops-app-prod"