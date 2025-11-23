# ECR Repository Outputs
output "repository_urls" {
  description = "Map of repository names to their URLs"
  value = {
    for name, repo in aws_ecr_repository.this : name => repo.repository_url
  }
}

output "repository_arns" {
  description = "Map of repository names to their ARNs"
  value = {
    for name, repo in aws_ecr_repository.this : name => repo.arn
  }
}

output "repository_registry_ids" {
  description = "Map of repository names to their registry IDs"
  value = {
    for name, repo in aws_ecr_repository.this : name => repo.registry_id
  }
}

output "repositories" {
  description = "Map of all repository details"
  value = {
    for name, repo in aws_ecr_repository.this : name => {
      name         = repo.name
      url          = repo.repository_url
      arn          = repo.arn
      registry_id  = repo.registry_id
    }
  }
}
