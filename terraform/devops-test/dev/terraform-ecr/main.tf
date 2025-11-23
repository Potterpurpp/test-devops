# Locals
locals {
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    Terraform   = "true"
  })
}

# ECR Module
module "ecr" {
  source = "../../../modules/ecr"

  # Project Configuration
  project_name = var.project_name
  environment  = var.environment
  region       = var.region

  # Repository Configuration
  repository_names     = var.repository_names
  image_tag_mutability = var.image_tag_mutability
  scan_on_push         = var.scan_on_push

  # Encryption Configuration
  encryption_type = var.encryption_type
  kms_key_id      = var.kms_key_id

  # Lifecycle Policy Configuration
  enable_lifecycle_policy = var.enable_lifecycle_policy
  max_image_count        = var.max_image_count
  untagged_image_days    = var.untagged_image_days

  tags = local.common_tags
}
