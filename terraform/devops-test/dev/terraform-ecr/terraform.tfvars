# Project Configuration
project_name = "devops-test"
environment  = "dev"
region       = "ap-southeast-1"

# ECR Repository Names
repository_names = [
  "test-devops-app-dev"
]

# Image Configuration
image_tag_mutability = "MUTABLE"  # Allow overwriting tags in dev
scan_on_push         = true       # Enable vulnerability scanning

# Encryption
encryption_type = "AES256"  # Use AES256 for dev (KMS for prod)

# Lifecycle Policy
enable_lifecycle_policy = true
max_image_count        = 10  # Keep last 10 tagged images
untagged_image_days    = 7   # Remove untagged images after 7 days

# Tags
tags = {
  Team       = "DevOps"
  ManagedBy  = "Terraform"
  CostCenter = "Engineering"
}