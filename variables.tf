# AWS 인증 변수 설정
variable "AWS_ACCESS_KEY_ID" {
  description = "AWS Access Key"
  type        = string
}

variable "AWS_SECRET_ACCESS_KEY" {
  description = "AWS Secret Key"
  type        = string
}

# RDS 변수 설정
variable "AWS_RDS_ID" {
  description = "RDS ID"
  type        = string
}

variable "AWS_RDS_PASSWORD" {
  description = "RDS PASSWORD"
  type        = string
}