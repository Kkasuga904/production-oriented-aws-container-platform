variable "name" { type = string }
variable "environment" { type = string }
variable "database_subnet_ids" { type = list(string) }
variable "database_security_group_id" { type = string }
variable "multi_az" { type = bool }
