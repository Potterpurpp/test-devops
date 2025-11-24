output "vpc_id" {
  description = "VPC ID created by module"
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "Public subnet ID created by module"
  value       = module.vpc.public_subnet_id
}
