# EC2 Outputs
output "ec2" {
  description = "EC2 instance details"
  value       = module.ec2.ec2_instance
}
