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

# 리전 변수를 정의합니다. 리전은 AWS 리소스가 생성될 곳입니다.
variable "aws_region" {
  description = "AWS 리전 지정"
  type        = string
  default     = "ap-northeast-2" # 기본 리전을 설정합니다.
}

# 가용 영역 변수를 정의합니다. 가용 영역은 AWS 리전 내의 데이터 센터입니다.
variable "ap_northeast_2a" {
  description = "AWS 가용 영역 지정"
  type        = string
  default     = "ap-northeast-2a" # 기본 가용 영역을 설정합니다.
}
variable "ap_northeast_2c" {
  description = "AWS 가용 영역 지정"
  type        = string
  default     = "ap-northeast-2c" # 기본 가용 영역을 설정합니다.
}

data "template_file" "setup_script" {
  template = file("${path.module}/userdata.sh.tpl")

  vars = {
    aws_access_key_id = var.AWS_ACCESS_KEY_ID
    aws_secret_access_key = var.AWS_SECRET_ACCESS_KEY
  }
}