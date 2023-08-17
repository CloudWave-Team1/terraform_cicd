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

# Application Load Balancer 보안 그룹 생성
resource "aws_security_group" "TFC_PRD_ELB_SG" {
  vpc_id = aws_vpc.TFC_PRD_VPC.id

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