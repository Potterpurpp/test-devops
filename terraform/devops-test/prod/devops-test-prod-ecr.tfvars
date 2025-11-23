# Project Configuration
project_name = "devops-test"
environment  = "prod"
region       = "ap-southeast-1"

# ECR Repository Names
repository_names = [
  "nodejs-app",
  "statsd",
  "graphite"
]

# Image Configuration
image_tag_mutability = "IMMUTABLE"  # Immutable tags for production
scan_on_push         = true         # Enable vulnerability scanning

# Encryption
encryption_type = "KMS"      # Use KMS encryption for production
kms_key_id      = null       # Replace with your KMS key ARN

# Lifecycle Policy
enable_lifecycle_policy = true
max_image_count        = 30  # Keep more production images
untagged_image_days    = 3   # Remove untagged images quickly

# Tags
tags = {
  Team       = "DevOps"
  ManagedBy  = "Terraform"
  CostCenter = "Engineering"
  Backup     = "Required"
  Compliance = "Required"
}
