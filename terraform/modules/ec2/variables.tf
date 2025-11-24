# Project Variable
variable "project_name" {
  description = "Name of the project"
  type        = string
}

# Environment Variable
variable "environment" {
  description = "Environment name (dev, sit, uat, prod)"
  type        = string
  validation {
    condition     = can(regex("^(dev|sit|uat|prod)$", var.environment))
    error_message = "Environment must be dev, sit, uat, or prod."
  }
}

# Region Variable
variable "region" {
  description = "AWS region"
  type        = string
}

# Tagging Variable
variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

# Instance Name Variable
variable "instance_name" {
  description = "Custom name for the EC2 instance"
  type        = string
  default     = null
}

# Instance Type Variable
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

# AMI ID Variable
variable "ami_id" {
  description = "AMI ID for the EC2 instance (null = use latest Amazon Linux 2023)"
  type        = string
  default     = null
}

# VPC and Networking Variable
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched"
  type        = string
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with the instance"
  type        = bool
  default     = false
}

variable "source_dest_check" {
  description = "Controls if traffic is routed to the instance when the destination address does not match the instance"
  type        = bool
  default     = true
}

# Key Pair Variable
variable "create_key_pair" {
  description = "Whether to create a new key pair"
  type        = bool
  default     = false
}

variable "key_pair_name" {
  description = "Name of the key pair to create"
  type        = string
  default     = null
}

variable "public_key" {
  description = "Public key content for the key pair"
  type        = string
  default     = null
}

variable "existing_key_pair_name" {
  description = "Name of existing key pair to use"
  type        = string
  default     = null
}

# Security Group Variable
variable "create_security_group" {
  description = "Whether to create a new security group"
  type        = bool
  default     = true
}

variable "security_group_name" {
  description = "Name of the security group to create"
  type        = string
  default     = null
}

variable "existing_security_group_ids" {
  description = "List of existing security group IDs to use"
  type        = list(string)
  default     = []
}

variable "ingress_rules" {
  description = "List of ingress rules for the security group"
  type = list(object({
    description      = string
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = list(string)
    ipv6_cidr_blocks = list(string)
    prefix_list_ids  = list(string)
    security_groups  = list(string)
    self             = bool
  }))
  default = []
}

variable "egress_rules" {
  description = "List of egress rules for the security group"
  type = list(object({
    description      = string
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = list(string)
    ipv6_cidr_blocks = list(string)
    prefix_list_ids  = list(string)
    security_groups  = list(string)
    self             = bool
  }))
  default = [
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
}

# IAM Variable
variable "create_iam_role" {
  description = "Whether to create a new IAM role and instance profile"
  type        = bool
  default     = false
}

variable "existing_iam_instance_profile" {
  description = "Name of existing IAM instance profile to use"
  type        = string
  default     = null
}

variable "iam_policy_arns" {
  description = "List of IAM policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "attach_ecr_managed_policy" {
  description = "Attach the AWS managed policy for ECR access (AmazonEC2ContainerRegistryPowerUser)"
  type        = bool
  default     = false
}

variable "ecr_repository_arns" {
  description = "Map of ECR repository ARNs to grant the instance role access to (name => arn)"
  type        = map(string)
  default     = {}
}

# User Data Variable
variable "user_data" {
  description = "User data script to run on instance startup"
  type        = string
  default     = null
}

variable "user_data_base64" {
  description = "Base64-encoded user data script"
  type        = string
  default     = null
}

# Block Device Variable
variable "root_block_device" {
  description = "Configuration for the root block device"
  type = object({
    volume_type           = string
    volume_size           = number
    iops                  = number
    throughput            = number
    encrypted             = bool
    kms_key_id            = string
    delete_on_termination = bool
  })
  default = null
}

variable "ebs_block_devices" {
  description = "List of additional EBS block devices"
  type = list(object({
    device_name           = string
    volume_type           = string
    volume_size           = number
    iops                  = number
    throughput            = number
    encrypted             = bool
    kms_key_id            = string
    snapshot_id           = string
    delete_on_termination = bool
  }))
  default = []
}

# Metadata Options Variable
variable "metadata_options" {
  description = "Metadata service options for the instance"
  type = object({
    http_endpoint               = string
    http_tokens                 = string
    http_put_response_hop_limit = number
    instance_metadata_tags      = string
  })
  default = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }
}

# CloudWatch Log Group Variable
variable "cloudwatch_log_group_retention_in_days" {
  description = "CloudWatch log group retention period in days"
  type        = number
  default     = 7
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "KMS key ID for CloudWatch log group encryption"
  type        = string
  default     = null
}

# Elastic IP Variable
variable "create_eip" {
  description = "Whether to create and associate an Elastic IP"
  type        = bool
  default     = false
}
