variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, sit, uat, prod)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Tags to add"
  type        = map(string)
  default     = {}
}

variable "vpc_name" {
  description = "Name tag for the VPC"
  type        = string
  default     = "devops-vpc"
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "availability_zone" {
  description = "Availability zone for the subnet (optional)"
  type        = string
  default     = null
}

variable "map_public_ip_on_launch" {
  description = "Whether to map public IPs on launch for the public subnet"
  type        = bool
  default     = true
}

variable "create_private_subnet" {
  description = "Whether to create a private subnet"
  type        = bool
  default     = false
}

variable "create_nat_gateway" {
  description = "Whether to create a NAT gateway for private subnet internet access"
  type        = bool
  default     = false
}

variable "private_subnet_suffix" {
  description = "Index suffix for private subnet (used with cidrsubnet)"
  type        = number
  default     = 1
}
