# Project Configuration
project_name = "practice-project"
environment  = "dev"
region       = "ap-southeast-7" # Change to your preferred region

# EC2 Configuration
ec2_instance_name               = "practice-dev-web-server"
ec2_instance_type               = "t3.micro" # Free tier eligible
ec2_ami_id                      = null       # null = use latest Amazon Linux 2023
ec2_associate_public_ip_address = true
ec2_source_dest_check           = true

# Networking Configuration
# IMPORTANT: Replace these with your actual VPC and Subnet IDs
vpc_id    = "vpc-xxxxxxxxxxxxxxxxx" # Replace with your VPC ID
subnet_id = "subnet-xxxxxxxxxxxxxxxxx" # Replace with your Subnet ID

# Security Group Configuration
ec2_create_security_group = true
ec2_security_group_name   = "practice-dev-web-server-sg"
ec2_ingress_rules = [
  {
    description      = "SSH access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] # WARNING: Restrict to your IP in production
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
    description      = "HTTPS access"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }
]
ec2_egress_rules = [
  {
    description      = "All outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }
]

# Key Pair Configuration
# Option 1: Create a new key pair (recommended for practice)
ec2_create_key_pair = false
ec2_key_pair_name   = null
ec2_public_key      = null

# Option 2: Use existing key pair (uncomment if you have one)
# ec2_create_key_pair        = false
# ec2_existing_key_pair_name = "your-existing-key-name"

# IAM Configuration
ec2_create_iam_role = true
ec2_iam_policy_arns = [
  "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" # For Systems Manager access
]

# User Data Script (optional - simple web server example)
ec2_user_data = <<-EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Hello from Terraform Practice!</h1>" > /var/www/html/index.html
EOF

# CloudWatch Configuration
ec2_cloudwatch_log_group_retention_in_days = 7

# Elastic IP Configuration (optional)
ec2_create_eip = false

# Tags
tags = {
  ManagedBy = "Terraform"
  Owner     = "DevOps-Team"
  Purpose   = "Practice"
}
