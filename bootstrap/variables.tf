variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "state_bucket_name" {
  description = "Globally unique bucket name selected by the operator."
  type        = string
}
