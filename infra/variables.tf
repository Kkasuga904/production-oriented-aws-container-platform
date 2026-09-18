variable "aws_region" {
  description = "AWS region used by the workload."
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Short name used in resource names and tags."
  type        = string
  default     = "platform-portfolio"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR allocated to the VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "Two AZs used by ALB, ECS, and RDS subnet groups."
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"]

  validation {
    condition     = length(var.availability_zones) == 2 && length(distinct(var.availability_zones)) == 2
    error_message = "Exactly two distinct availability zones are required."
  }
}

variable "image_tag" {
  description = "Immutable application image tag, normally a Git commit SHA."
  type        = string
  default     = "bootstrap"

  validation {
    condition     = var.image_tag != "latest"
    error_message = "latest is intentionally prohibited; use a Git SHA or another immutable identifier."
  }
}

variable "enable_service" {
  description = "Enable ECS tasks after the selected image tag has been pushed to ECR."
  type        = bool
  default     = false
}

variable "db_multi_az" {
  description = "Enable an RDS standby in a second AZ. Disabled by default for portfolio cost control."
  type        = bool
  default     = false
}

variable "alarm_email" {
  description = "Optional email endpoint for alarm notifications. Subscription confirmation is required."
  type        = string
  default     = null
  nullable    = true
}
