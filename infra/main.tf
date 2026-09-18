module "network" {
  source = "./modules/network"

  name               = local.name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "database" {
  source = "./modules/database"

  name                       = local.name
  environment                = var.environment
  database_subnet_ids        = module.network.database_subnet_ids
  database_security_group_id = aws_security_group.database.id
  multi_az                   = var.db_multi_az
}

module "service" {
  source = "./modules/service"

  name                  = local.name
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  private_subnet_ids    = module.network.private_subnet_ids
  database_host         = module.database.address
  database_secret_arn   = module.database.master_user_secret_arn
  alb_security_group_id = aws_security_group.alb.id
  ecs_security_group_id = aws_security_group.ecs.id
  image_tag             = var.image_tag
  desired_count         = var.enable_service ? 2 : 0
}

module "monitoring" {
  source = "./modules/monitoring"

  name                    = local.name
  alb_arn_suffix          = module.service.alb_arn_suffix
  target_group_arn_suffix = module.service.target_group_arn_suffix
  ecs_cluster_name        = module.service.ecs_cluster_name
  ecs_service_name        = module.service.ecs_service_name
  db_instance_id          = module.database.instance_id
  alarm_email             = var.alarm_email
}
