output "alb_dns_name" { value = aws_lb.this.dns_name }
output "alb_arn_suffix" { value = aws_lb.this.arn_suffix }
output "target_group_arn_suffix" { value = aws_lb_target_group.this.arn_suffix }
output "ecs_cluster_name" { value = aws_ecs_cluster.this.name }
output "ecs_service_name" { value = aws_ecs_service.this.name }
output "ecr_repository_url" { value = aws_ecr_repository.this.repository_url }
output "ecs_desired_count" { value = aws_ecs_service.this.desired_count }
