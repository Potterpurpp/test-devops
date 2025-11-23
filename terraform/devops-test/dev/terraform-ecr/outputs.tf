# ECR Outputs
output "ecr" {
  description = "ECR repositories details"
  value       = module.ecr.repositories
}

output "repository_urls" {
  description = "Map of repository names to their URLs"
  value       = module.ecr.repository_urls
}

output "repository_arns" {
  description = "Map of repository names to their ARNs"
  value       = module.ecr.repository_arns
}

output "repository_registry_ids" {
  description = "Map of repository names to their registry IDs"
  value       = module.ecr.repository_registry_ids
}
