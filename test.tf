provider "aws" {
  region = "ap-northeast-2"
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

# NAT Gateway 생성
resource "aws_eip" "NAT_EIP" {
  count = 2
}

resource "aws_nat_gateway" "TFC_PRD_NG" {
  count         = 2
  subnet_id     = aws_subnet.TFC_PRD_sub[count.index].id
  allocation_id = aws_eip.NAT_EIP[count.index].id
}

# Security Groups 생성
resource "aws_security_group" "TFC_PRD_ELB_SG" {
  vpc_id = aws_vpc.TFC_PRD_VPC.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/24"]
  }

  tags = {
    Name = "TFC-PRD-ELB-SG"
  }
}

resource "aws_security_group" "TFC_PRD_EC2_SG" {
  vpc_id = aws_vpc.TFC_PRD_VPC.id

  # 여기에 인바운드 규칙 추가

  tags = {
    Name = "TFC-PRD-EC2-SG"
  }
}

# Launch Template 생성
resource "aws_launch_template" "TFC_EC2_template" {
  name_prefix   = "TFC-EC2-template"
  description   = "TFC EC2 basic start"
  image_id      = "ami-055179a7fc9fb032d"
  instance_type = "t2.micro"

  user_data = <<-EOT
              #!/bin/bash
              yum install -y httpd
              echo "Hello, TFC" > /var/www/html/index.html
              systemctl start httpd
              systemctl enable httpd
              EOT

  vpc_security_group_ids = [aws_security_group.TFC_PRD_EC2_SG.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "TFC EC2 Instance"
    }
  }
}

# Application Load Balancer (ALB) 설정
resource "aws_lb" "TFC_PRD_ELB" {
  name               = "TFC-PRD-ELB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.TFC_PRD_ELB_SG.id]
  subnets            = [aws_subnet.TFC_PRD_sub[2].id, aws_subnet.TFC_PRD_sub[3].id]

  enable_deletion_protection = false

  tags = {
    Name = "TFC-PRD-ELB"
  }
}

# Target Group 설정
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
}

# Listener 설정
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.TFC_PRD_ELB.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TFC_PRD_TG.arn
  }
}

# Auto Scaling Group 설정
resource "aws_autoscaling_group" "TFC_PRD_ASGP" {
  desired_capacity     = 1
  max_size             = 2
  min_size             = 1
  launch_template {
    id      = aws_launch_template.TFC_EC2_template.id
    version = "$Latest"
  }
  vpc_zone_identifier  = [aws_subnet.TFC_PRD_sub[2].id, aws_subnet.TFC_PRD_sub[3].id]
  target_group_arns    = [aws_lb_target_group.TFC_PRD_TG.arn]

  tag {
    key                 = "Name"
    value               = "TFC-ASG-Instance"
    propagate_at_launch = true
  }
}

# Scaling Policy
resource "aws_autoscaling_policy" "TFC_PRD_ASGP_TTP" {
  name                   = "TFC-PRD-ASGP-TTP"
  autoscaling_group_name = aws_autoscaling_group.TFC_PRD_ASGP.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}