mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      region = "ap-northeast-1"
    }
  }
}

run "portfolio_plan" {
  command = plan

  override_resource {
    target          = aws_security_group.alb
    override_during = plan
    values = {
      id = "sg-mock-alb"
    }
  }

  override_resource {
    target          = module.network.aws_vpc_endpoint.s3
    override_during = plan
    values = {
      prefix_list_id = "pl-mock-s3"
    }
  }

  override_resource {
    target          = aws_security_group.ecs
    override_during = plan
    values = {
      id = "sg-mock-ecs"
    }
  }

  variables {
    environment        = "dev"
    availability_zones = ["ap-northeast-1a", "ap-northeast-1c"]
    image_tag          = "0123456789abcdef0123456789abcdef01234567"
    enable_service     = false
    db_multi_az        = false
  }

  assert {
    condition     = length(module.network.public_subnet_ids) == 2
    error_message = "The public ALB tier must span exactly two subnets."
  }

  assert {
    condition     = length(module.network.private_subnet_ids) == 2
    error_message = "The ECS tier must span exactly two private subnets."
  }

  assert {
    condition     = length(module.network.database_subnet_ids) == 2
    error_message = "The RDS subnet group must span exactly two database subnets."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.alb_http.cidr_ipv4 == "0.0.0.0/0"
    error_message = "Only the public ALB listener should accept internet ingress."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.ecs_from_alb.referenced_security_group_id == aws_security_group.alb.id
    error_message = "ECS ingress must reference the ALB security group."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.database_from_ecs.referenced_security_group_id == aws_security_group.ecs.id
    error_message = "Database ingress must reference the ECS security group."
  }

  assert {
    condition     = module.service.ecs_desired_count == 0
    error_message = "The bootstrap plan must not start tasks before an image is pushed."
  }

  assert {
    condition     = aws_vpc_security_group_egress_rule.ecs_to_s3.prefix_list_id == "pl-mock-s3"
    error_message = "ECS must reach ECR image layers through the S3 gateway endpoint prefix list."
  }
}

run "enabled_service_plan" {
  command = plan

  variables {
    image_tag      = "fedcba9876543210fedcba9876543210fedcba98"
    enable_service = true
  }

  assert {
    condition     = module.service.ecs_desired_count == 2
    error_message = "An enabled service must run two tasks across the private tier."
  }
}
