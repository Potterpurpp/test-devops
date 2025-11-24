# Locals
locals {
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    Terraform   = "true"
  })
}

# Generate user data from per-environment template (../user_data.tpl) if present,
# otherwise fall back to a component-local user_data.tpl inside this module.
locals {
  user_data_template_path = fileexists("${path.module}/../user_data.tpl") ? "${path.module}/../user_data.tpl" : (
    fileexists("${path.module}/user_data.tpl") ? "${path.module}/user_data.tpl" : ""
  )

  ec2_user_data = local.user_data_template_path != "" ? templatefile(local.user_data_template_path, {
    project_name        = var.project_name,
    environment         = var.environment,
    region              = var.region,
    git_repo            = var.ec2_git_repo,
    image_name          = var.ec2_image_name,
    image_tag           = var.ec2_image_tag,
    ecr_registry        = lookup(var.ec2_ecr_repository_urls, var.ec2_image_name, (
                            var.ec2_ecr_registry_dev != "" ? var.ec2_ecr_registry_dev : (
                            var.ec2_ecr_registry_uat != "" ? var.ec2_ecr_registry_uat : var.ec2_ecr_registry_prod)))
  }) : null
}

# If vpc_id / subnet_id are not supplied, attempt to discover the VPC by Name tag
data "aws_vpc" "by_name" {
  count = var.vpc_id == null ? 1 : 0
  filter {
    name   = "tag:Name"
    values = [var.vpc_name != null ? var.vpc_name : "${var.project_name}-vpc"]
  }
}

data "aws_subnets" "vpc_subnets" {
  count = var.subnet_id == null && var.vpc_id == null ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.by_name[0].id]
  }
}

locals {
  effective_vpc_id    = var.vpc_id != null ? var.vpc_id : (length(data.aws_vpc.by_name) > 0 ? data.aws_vpc.by_name[0].id : null)
  effective_subnet_id = var.subnet_id != null ? var.subnet_id : (length(data.aws_subnets.vpc_subnets) > 0 ? data.aws_subnets.vpc_subnets[0].ids[0] : null)
}

# EC2 Module
module "ec2" {
  source = "../../../modules/ec2"

  # Project Configuration
  project_name = var.project_name
  environment  = var.environment
  region       = var.region

  # Instance Configuration
  instance_name = var.ec2_instance_name
  instance_type = var.ec2_instance_type
  ami_id        = var.ec2_ami_id

  # Networking Configuration
  vpc_id                      = local.effective_vpc_id
  subnet_id                   = local.effective_subnet_id
  associate_public_ip_address = var.ec2_associate_public_ip_address
  source_dest_check           = var.ec2_source_dest_check

  # Security Group Configuration
  create_security_group       = var.ec2_create_security_group
  security_group_name         = var.ec2_security_group_name
  existing_security_group_ids = var.ec2_existing_security_group_ids
  ingress_rules               = var.ec2_ingress_rules
  egress_rules                = var.ec2_egress_rules

  # Key Pair Configuration
  create_key_pair        = var.ec2_create_key_pair
  key_pair_name          = var.ec2_key_pair_name
  public_key             = var.ec2_public_key
  existing_key_pair_name = var.ec2_existing_key_pair_name

  # IAM Configuration
  create_iam_role               = var.ec2_create_iam_role
  existing_iam_instance_profile = var.ec2_existing_iam_instance_profile
  iam_policy_arns               = var.ec2_iam_policy_arns

  # User Data Configuration
  user_data        = local.ec2_user_data
  user_data_base64 = var.ec2_user_data_base64

  # Block Device Configuration
  root_block_device = var.ec2_root_block_device
  ebs_block_devices = var.ec2_ebs_block_devices

  # Metadata Configuration
  metadata_options = var.ec2_metadata_options

  # CloudWatch Configuration
  cloudwatch_log_group_retention_in_days = var.ec2_cloudwatch_log_group_retention_in_days
  cloudwatch_log_group_kms_key_id        = var.ec2_cloudwatch_log_group_kms_key_id

  # Elastic IP Configuration
  create_eip = var.ec2_create_eip

  tags = local.common_tags
}
