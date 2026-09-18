resource "aws_db_subnet_group" "this" {
  name       = var.name
  subnet_ids = var.database_subnet_ids
}

resource "aws_db_instance" "this" {
  identifier = var.name

  engine         = "postgres"
  engine_version = "17.6"
  instance_class = "db.t4g.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name                     = "app"
  username                    = "appadmin"
  manage_master_user_password = true
  port                        = 5432

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.database_security_group_id]
  publicly_accessible    = false
  multi_az               = var.multi_az

  backup_retention_period   = var.environment == "prod" ? 14 : 1
  deletion_protection       = var.environment == "prod"
  skip_final_snapshot       = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "${var.name}-final" : null
  copy_tags_to_snapshot     = true

  auto_minor_version_upgrade   = true
  apply_immediately            = var.environment != "prod"
  performance_insights_enabled = var.environment == "prod"

  lifecycle {
    prevent_destroy = false
  }
}
