output "alb_url" {
  description = "Public HTTP endpoint. Production should add an ACM certificate and HTTPS listener."
  value       = "http://${module.service.alb_dns_name}"
}

output "ecr_repository_url" {
  description = "Push the application image here before enabling the service."
  value       = module.service.ecr_repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster used by deployment verification."
  value       = module.service.ecs_cluster_name
}

output "ecs_service_name" {
  description = "ECS service used by deployment verification."
  value       = module.service.ecs_service_name
}

output "database_secret_arn" {
  description = "ARN of the RDS-managed master-user secret."
  value       = module.database.master_user_secret_arn
}
