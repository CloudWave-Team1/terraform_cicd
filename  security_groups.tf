# EC2 보안 그룹 생성
resource "aws_security_group" "TFC_PRD_EC2_SG" {
  vpc_id = aws_vpc.TFC_PRD_VPC.id

  # VPC 내부에서 모든 포트에 대한 TCP 트래픽을 허용
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.TFC_PRD_VPC.cidr_block]
  }
  
  # 모든 대상에 대해 모든 포트로의 나가는 트래픽을 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "TFC-PRD-EC2-SG"
  }
}

# Application Load Balancer 보안 그룹 생성
resource "aws_security_group" "TFC_PRD_ALB_SG" {
  vpc_id = aws_vpc.TFC_PRD_VPC.id

  # 모든 소스에서 80, 8089, 443 포트로의 TCP 트래픽을 허용
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8089
    to_port     = 8089
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 모든 대상에 대해 모든 포트로의 나가는 트래픽을 허용
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "TFC-PRD-ALB-SG"
  }
}

# RDS 보안 그룹 생성
resource "aws_security_group" "TFC_PRD_RDS_SG" {
  vpc_id = aws_vpc.TFC_PRD_VPC.id

  # TFC-PRD-ELB-SG 및 TFC-PRD-EC2-SG 보안 그룹에서 모든 포트와 프로토콜의 트래픽을 허용
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.TFC_PRD_ALB_SG.id]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.TFC_PRD_EC2_SG.id]
  }

  # 모든 대상에 대해 모든 포트로의 나가는 트래픽을 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "TFC-PRD-RDS-SG"
  }
}