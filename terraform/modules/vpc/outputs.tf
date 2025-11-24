output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "Private subnet ID (if created)"
  value       = try(aws_subnet.private[0].id, null)
}

output "nat_gateway_id" {
  description = "NAT Gateway ID (if created)"
  value       = try(aws_nat_gateway.nat[0].id, null)
}

output "availability_zone" {
  description = "Availability zone used"
  value       = aws_subnet.public.availability_zone
}
