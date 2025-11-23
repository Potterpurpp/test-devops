# Project Variable
variable "project_name" {
  description = "Name of the project"
  type        = string
}

# Environment Variable
variable "environment" {
  description = "Environment name (dev, uat, prod)"
  type        = string
}

# Region Variable
variable "region" {
  description = "AWS region"
  type        = string
}

# ECR Repository Names
variable "repository_names" {
  description = "List of ECR repository names to create"
  type        = list(string)
  default     = []
}

# Image Tag Mutability
variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
  validation {
    condition     = can(regex("^(MUTABLE|IMMUTABLE)$", var.image_tag_mutability))
    error_message = "Image tag mutability must be MUTABLE or IMMUTABLE."
  }
}

# Image Scanning Configuration
variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository"
  type        = bool
  default     = true
}

# Encryption Configuration
variable "encryption_type" {
  description = "The encryption type to use for the repository (AES256 or KMS)"
  type        = string
  default     = "AES256"
  validation {
    condition     = can(regex("^(AES256|KMS)$", var.encryption_type))
    error_message = "Encryption type must be AES256 or KMS."
  }
}

variable "kms_key_id" {
  description = "The ARN of the KMS key to use when encryption_type is KMS"
  type        = string
  default     = null
}

# Lifecycle Policy
variable "enable_lifecycle_policy" {
  description = "Enable lifecycle policy for the repositories"
  type        = bool
  default     = true
}

variable "max_image_count" {
  description = "Maximum number of images to keep in the repository"
  type        = number
  default     = 10
}

variable "untagged_image_days" {
  description = "Number of days to keep untagged images"
  type        = number
  default     = 7
}

# Tagging Variable
variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
