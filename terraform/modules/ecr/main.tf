# Locals
locals {
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    Terraform   = "true"
  })

  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.max_image_count} images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = var.max_image_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Remove untagged images older than ${var.untagged_image_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_image_days
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECR Repositories
resource "aws_ecr_repository" "this" {
  for_each = toset(var.repository_names)

  name                 = "${var.project_name}-${var.environment}-${each.value}"
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.kms_key_id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-${each.value}"
  })
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "this" {
  for_each = var.enable_lifecycle_policy ? toset(var.repository_names) : []

  repository = aws_ecr_repository.this[each.value].name
  policy     = local.lifecycle_policy
}

# ECR Repository Policy (allow pull from same account)
resource "aws_ecr_repository_policy" "this" {
  for_each = toset(var.repository_names)

  repository = aws_ecr_repository.this[each.value].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPullFromSameAccount"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
