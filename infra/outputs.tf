output "alb_url" {
  description = "Public HTTP endpoint. Production should add an ACM certificate and HTTPS listener."
  value       = "http://${module.service.alb_dns_name}"
}

output "ecr_repository_url" {
  description = "Push the application image here before enabling the service."
  value       = module.service.ecr_repository_url
}

output "database_secret_arn" {
  description = "ARN of the RDS-managed master-user secret."
  value       = module.database.master_user_secret_arn
}
