# VPC 생성
# test

# AWS 프로바이더 설정
provider "aws" {
  region  = "ap-northeast-2"
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
}

resource "aws_vpc" "TFC_PRD_VPC" {
  cidr_block = "10.3.0.0/16"

  tags = {
    Name = "TFC-PRD-VPC"
  }
}

# Subnet 생성
resource "aws_subnet" "TFC_PRD_sub" {
  count = 6

  availability_zone = count.index < 6 ? ["ap-northeast-2a", "ap-northeast-2c"][count.index] : null
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

# Internet Gateway 생성
resource "aws_internet_gateway" "TFC_PRD_IG" {
  vpc_id = aws_vpc.TFC_PRD_VPC.id

  tags = {
    Name = "TFC-PRD-IG"
  }
}

resource "aws_eip" "example" {
  count = 2
}

# NAT Gateway 생성
resource "aws_nat_gateway" "TFC_PRD_NG" {
  count         = 2
  allocation_id = aws_eip.example[count.index].id
  subnet_id     = aws_subnet.TFC_PRD_sub[count.index].id

  tags = {
    Name = ["TFC-PRD-NG01", "TFC-PRD-NG02"][count.index]
  }
}

# Launch Template 생성
resource "aws_launch_template" "TFC_EC2_template" {
  description   = "TFC EC2 basic start"
  image_id      = "ami-055179a7fc9fb032d"
  instance_type = "t2.micro"
  name_prefix   = "TFC-EC2-template"
}

# Auto Scaling Group 생성
resource "aws_autoscaling_group" "TFC_PRD_ASGP" {
  # availability_zones = ["ap-northeast-2a", "ap-northeast-2c"]
  desired_capacity   = 1
  max_size           = 2
  min_size           = 1
  vpc_zone_identifier = [
    aws_subnet.TFC_PRD_sub[0].id, 
    aws_subnet.TFC_PRD_sub[1].id
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

# ELB 및 관련 리소스 생성
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

resource "aws_lb" "TFC_PRD_ELB" {
  internal           = false
  load_balancer_type = "application"
  name               = "TFC-PRD-ELB"
  security_groups    = [aws_security_group.TFC_PRD_ELB_SG.id]
  subnets            = [aws_subnet.TFC_PRD_sub[0].id, aws_subnet.TFC_PRD_sub[1].id]
}

resource "aws_lb_target_group" "TFC_PRD_ELB_GP" {
  name     = "TFC-PRD-ELB-GP"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.TFC_PRD_VPC.id
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.TFC_PRD_ELB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.TFC_PRD_ELB_GP.arn
    type             = "forward"
  }
}

# Auto Scaling Group의 크기 조정 정책
resource "aws_autoscaling_policy" "TFC_PRD_ASGP_TTP" {
  autoscaling_group_name = aws_autoscaling_group.TFC_PRD_ASGP.name
  name                   = "TFC-PRD-ASGP-TTP"
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}