# Locals
locals {
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    Terraform   = "true"
  })
}

module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  region       = var.region

  vpc_name = var.vpc_name
  cidr_block = var.cidr_block
  availability_zone = var.availability_zone
  map_public_ip_on_launch = var.map_public_ip_on_launch
  create_private_subnet = var.create_private_subnet
  create_nat_gateway = var.create_nat_gateway

  tags = local.common_tags
}
