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
  user_data = base64encode(file("./userdata.sh"))

  vpc_security_group_ids = [aws_security_group.TFC_PRD_EC2_SG.id]
}

# EC2 보안 그룹 생성
resource "aws_security_group" "TFC_PRD_EC2_SG" {
  vpc_id = aws_vpc.TFC_PRD_VPC.id
  
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.TFC_PRD_VPC.cidr_block]
  }
  
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

# Target Group 생성
resource "aws_lb_target_group" "TFC_PRD_TG" {
  name     = "TFC-PRD-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.TFC_PRD_VPC.id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "80"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "TFC-PRD-TG"
  }
}

# Application Load Balancer 생성
resource "aws_lb" "TFC_PRD_ELB" {
  internal           = false
  load_balancer_type = "application"
  name               = "TFC-PRD-ELB"
  security_groups    = [aws_security_group.TFC_PRD_ELB_SG.id]
  subnets            = [aws_subnet.TFC_PRD_sub[0].id, aws_subnet.TFC_PRD_sub[1].id]
  enable_deletion_protection = false
  tags = {
    Name = "TFC-PRD-ELB"
  }
}

# ALB 리스너에서 대상 그룹을 default action으로 설정
resource "aws_lb_listener" "TFC_PRD_Listener" {
  load_balancer_arn = aws_lb.TFC_PRD_ELB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TFC_PRD_TG.arn
  }
}

# EC2 자동 확장 그룹 설정
resource "aws_autoscaling_group" "TFC_PRD_ASG" {
  desired_capacity     = 2
  max_size             = 5
  min_size             = 1
  vpc_zone_identifier  = [aws_subnet.TFC_PRD_sub[2].id, aws_subnet.TFC_PRD_sub[3].id]
  target_group_arns    = [aws_lb_target_group.TFC_PRD_TG.arn]
  launch_template {
    id      = aws_launch_template.TFC_EC2_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "TFC-PRD-EC2"
    propagate_at_launch = true
  }
}

# Target Tracking Scaling Policy
resource "aws_autoscaling_policy" "TFC_PRD_ASG_Policy" {
  name                   = "TFC-PRD-ASG-Policy"
  autoscaling_group_name = aws_autoscaling_group.TFC_PRD_ASG.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}

# Application Load Balancer 보안 그룹 생성
resource "aws_security_group" "TFC_PRD_ELB_SG" {
  vpc_id = aws_vpc.TFC_PRD_VPC.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "TFC-PRD-ELB-SG"
  }
}

# Private Subnet의 라우팅 테이블 생성
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.TFC_PRD_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.TFC_PRD_NG[0].id
  }

  tags = {
    Name = "TFC-PRD-Private-RT"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.TFC_PRD_sub[2].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.TFC_PRD_sub[3].id
  route_table_id = aws_route_table.private.id
}

# Public Subnet의 라우팅 테이블 생성
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.TFC_PRD_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.TFC_PRD_NG[0].id
  }

  tags = {
    Name = "TFC-PRD-Public-RT"
  }
}

# 퍼블릿 서브넷에 라우팅 테이블 연결
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.TFC_PRD_sub[0].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.TFC_PRD_sub[1].id
  route_table_id = aws_route_table.public.id
}

# 인터넷 게이트웨이 생성
resource "aws_internet_gateway" "TFC_PRD_IG" {
  vpc_id = aws_vpc.TFC_PRD_VPC.id
  tags = {
    Name = "TFC-PRD-IG"
  }
}

# VPC에 라우팅 테이블을 생성하고 인터넷 게이트웨이로 라우팅
resource "aws_route_table" "TFC_PRD_RT" {
  vpc_id = aws_vpc.TFC_PRD_VPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.TFC_PRD_IG.id
  }
  tags = {
    Name = "TFC-PRD-RT"
  }
}