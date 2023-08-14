# AWS 인증 변수 설정
variable "AWS_ACCESS_KEY_ID" {
  description = "AWS Access Key"
  type        = string
}

variable "AWS_SECRET_ACCESS_KEY" {
  description = "AWS Secret Key"
  type        = string
}

# AWS 프로바이더 설정
provider "aws" {
  region  = "ap-northeast-2"
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
}

# VPC 생성
resource "aws_vpc" "TFC_PRD_VPC" {
  cidr_block = "10.3.0.0/16"
  tags = {
    Name = "TFC-PRD-VPC"
  }
}

# 6개의 서브넷 생성 설정
resource "aws_subnet" "TFC_PRD_sub" {
  count = 6

  availability_zone = ["ap-northeast-2a", "ap-northeast-2c"][count.index % 2]
  cidr_block        = [
    "10.3.1.0/24",
    "10.3.2.0/24",
    "10.3.11.0/24",
    "10.3.12.0/24",
    "10.3.13.0/24",
    "10.3.14.0/24"
  ][count.index]
  vpc_id = aws_vpc.TFC_PRD_VPC.id
  tags = {
    Name = ["TFC-PRD-sub-pub-01", "TFC-PRD-sub-pub-02", "TFC-PRD-sub-pri-01", "TFC-PRD-sub-pri-02", "TFC-PRD-sub-pri-03", "TFC-PRD-sub-pri-04"][count.index]
  }
}

# 인터넷 게이트웨이 생성
resource "aws_internet_gateway" "TFC_PRD_IG" {
  vpc_id = aws_vpc.TFC_PRD_VPC.id
  tags = {
    Name = "TFC-PRD-IG"
  }
}

# 공개 IP 주소(EIP) 생성
resource "aws_eip" "example" {
  count = 2
}

# NAT 게이트웨이 생성
resource "aws_nat_gateway" "TFC_PRD_NG" {
  count         = 2
  allocation_id = aws_eip.example[count.index].id
  subnet_id     = aws_subnet.TFC_PRD_sub[count.index].id
  tags = {
    Name = ["TFC-PRD-NG01", "TFC-PRD-NG02"][count.index]
  }
}

# EC2 인스턴스 생성을 위한 템플릿
resource "aws_launch_template" "TFC_EC2_template" {
  description   = "TFC EC2 basic start"
  image_id      = "ami-055179a7fc9fb032d"
  instance_type = "t2.micro"
  name_prefix   = "TFC-EC2-template"
  user_data = base64encode(file("./test.sh")) # 테스트용

  # 여기에 보안 그룹 지정
  vpc_security_group_ids = [aws_security_group.TFC_PRD_EC2_SG.id]
}

# EC2 보안 그룹 생성
resource "aws_security_group" "TFC_PRD_EC2_SG" {
  vpc_id = aws_vpc.TFC_PRD_VPC.id
  
  # VPC 내부 트래픽만 허용
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.TFC_PRD_VPC.cidr_block]
  }
  
  # 모든 외부로 나가는 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "TFC-PRD-EC2-SG"
  }
}

# EC2 자동 확장 그룹 설정
resource "aws_autoscaling_group" "TFC_PRD_ASGP" {
  desired_capacity   = 1
  max_size           = 2
  min_size           = 1
  
  # 특정 서브넷들에 대해 인스턴스 생성
  vpc_zone_identifier = [
    aws_subnet.TFC_PRD_sub[2].id,  # TFC-PRD-sub-pri-01
    aws_subnet.TFC_PRD_sub[3].id   # TFC-PRD-sub-pri-02
  ]

  launch_template {
    id      = aws_launch_template.TFC_EC2_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "TFC-PRD-ASGP"
  }
}

# Application Load Balancer 보안 그룹 생성
resource "aws_security_group" "TFC_PRD_ELB_SG" {
  vpc_id = aws_vpc.TFC_PRD_VPC.id
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
  ingress {
    cidr_blocks = ["0.0.0.0/24"]
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
  }
  tags = {
    Name = "TFC-PRD-ELB-SG"
  }
}

# Application Load Balancer 생성
resource "aws_lb" "TFC_PRD_ELB" {
  internal           = false
  load_balancer_type = "application"
  name               = "TFC-PRD-ELB"
  security_groups    = [aws_security_group.TFC_PRD_ELB_SG.id]
  subnets            = [aws_subnet.TFC_PRD_sub[0].id, aws_subnet.TFC_PRD_sub[1].id] # 공개 서브넷
  enable_deletion_protection = false
  tags = {
    Name = "TFC-PRD-ELB"
  }
}

# Application Load Balancer 리스너 설정
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.TFC_PRD_ELB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "200"
    }
  }
}