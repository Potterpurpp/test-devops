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

# EC2 Instance Name Variable
variable "ec2_instance_name" {
  description = "Custom name for the EC2 instance"
  type        = string
  default     = null
}

# EC2 Instance Type Variable
variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

# EC2 AMI ID Variable
variable "ec2_ami_id" {
  description = "AMI ID for the EC2 instance (null = use latest Amazon Linux 2023)"
  type        = string
  default     = null
}

# EC2 Associate Public IP Address Variable
variable "ec2_associate_public_ip_address" {
  description = "Whether to associate a public IP address with the instance"
  type        = bool
  default     = true
}

# EC2 Source Dest Check Variable
variable "ec2_source_dest_check" {
  description = "Controls if traffic is routed to the instance when the destination address does not match the instance"
  type        = bool
  default     = true
}

# VPC ID Variable
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

# Subnet ID Variable
variable "subnet_id" {
  description = "Subnet ID where the instance will be launched"
  type        = string
}

# EC2 Create Security Group Variable
variable "ec2_create_security_group" {
  description = "Whether to create a new security group for EC2"
  type        = bool
  default     = true
}

# EC2 Security Group Name Variable
variable "ec2_security_group_name" {
  description = "Name of the security group to create for EC2"
  type        = string
  default     = null
}

# EC2 Existing Security Group IDs Variable
variable "ec2_existing_security_group_ids" {
  description = "List of existing security group IDs to use for EC2"
  type        = list(string)
  default     = []
}

# EC2 Ingress Rules Variable
variable "ec2_ingress_rules" {
  description = "List of ingress rules for the EC2 security group"
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

# EC2 Egress Rules Variable
variable "ec2_egress_rules" {
  description = "List of egress rules for the EC2 security group"
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

# EC2 Create Key Pair Variable
variable "ec2_create_key_pair" {
  description = "Whether to create a new key pair for EC2"
  type        = bool
  default     = false
}

# EC2 Key Pair Name Variable
variable "ec2_key_pair_name" {
  description = "Name of the key pair to create for EC2"
  type        = string
  default     = null
}

# EC2 Public Key Variable
variable "ec2_public_key" {
  description = "Public key content for the EC2 key pair"
  type        = string
  default     = null
}

# EC2 Existing Key Pair Name Variable
variable "ec2_existing_key_pair_name" {
  description = "Name of existing key pair to use for EC2"
  type        = string
  default     = null
}

# EC2 IAM Variable
variable "ec2_create_iam_role" {
  description = "Whether to create a new IAM role and instance profile for EC2"
  type        = bool
  default     = false
}

# EC2 Existing IAM Instance Profile Variable
variable "ec2_existing_iam_instance_profile" {
  description = "Name of existing IAM instance profile to use for EC2"
  type        = string
  default     = null
}

# EC2 IAM Policy ARNs Variable
variable "ec2_iam_policy_arns" {
  description = "List of IAM policy ARNs to attach to the EC2 role"
  type        = list(string)
  default     = []
}

# EC2 User Data Script Variable
variable "ec2_user_data" {
  description = "User data script to run on EC2 instance startup"
  type        = string
  default     = null
}

# EC2 User Data Base64 Variable
variable "ec2_user_data_base64" {
  description = "Base64-encoded user data script for EC2"
  type        = string
  default     = null
}

# EC2 Root Block Device Variable
variable "ec2_root_block_device" {
  description = "Configuration for the EC2 root block device"
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

# EC2 EBS Block Devices Variable
variable "ec2_ebs_block_devices" {
  description = "List of additional EBS block devices for EC2"
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

# EC2 Metadata Service Options Variable
variable "ec2_metadata_options" {
  description = "Metadata service options for the EC2 instance"
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

# EC2 CloudWatch Log Group Retention In Days Variable
variable "ec2_cloudwatch_log_group_retention_in_days" {
  description = "CloudWatch log group retention period in days for EC2"
  type        = number
  default     = 7
}

# EC2 CloudWatch Log Group KMS Key ID Variable
variable "ec2_cloudwatch_log_group_kms_key_id" {
  description = "KMS key ID for EC2 CloudWatch log group encryption"
  type        = string
  default     = null
}

# EC2 Create Elastic IP Variable
variable "ec2_create_eip" {
  description = "Whether to create and associate an Elastic IP for EC2"
  type        = bool
  default     = false
}
