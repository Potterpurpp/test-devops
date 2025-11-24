variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev|uat|prod)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Tags map"
  type        = map(string)
  default     = {}
}

variable "vpc_name" {
  description = "Name for the VPC"
  type        = string
  default     = "devops-test-vpc"
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "availability_zone" {
  description = "AZ to place the public subnet (optional)"
  type        = string
  default     = null
}

variable "map_public_ip_on_launch" {
  description = "Whether public subnet auto-assigns public IPs"
  type        = bool
  default     = true
}

variable "create_private_subnet" {
  description = "Create a private subnet in this VPC"
  type        = bool
  default     = false
}

variable "create_nat_gateway" {
  description = "Create a NAT gateway for private subnet internet access"
  type        = bool
  default     = false
}
