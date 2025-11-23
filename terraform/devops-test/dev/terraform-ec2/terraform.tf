# Terraform Configuration
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend Configuration (comment out for local state)
  # Uncomment and configure when ready to use remote state
  # backend "s3" {
  #   bucket  = "your-terraform-state-bucket"
  #   key     = "practice/ec2/terraform.tfstate"
  #   region  = "ap-southeast-1"
  #   encrypt = true
  # }
}
