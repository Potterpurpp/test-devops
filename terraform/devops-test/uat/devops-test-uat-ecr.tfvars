# Project Configuration
project_name = "devops-test"
environment  = "uat"
region       = "ap-southeast-1"

# ECR Repository Names
repository_names = [
  "test-devops-app-uat"
]

# Image Configuration
image_tag_mutability = "MUTABLE"  # Still mutable for UAT
scan_on_push         = true       # Enable vulnerability scanning

# Encryption
encryption_type = "AES256"  # Use AES256 for UAT

# Lifecycle Policy
enable_lifecycle_policy = true
max_image_count        = 15  # Keep more images in UAT
untagged_image_days    = 14  # Keep untagged images longer

# Tags
tags = {
  Team       = "DevOps"
  ManagedBy  = "Terraform"
  CostCenter = "Engineering"
}
