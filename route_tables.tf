# Private Subnet의 라우팅 테이블 생성
resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.TFC_PRD_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.TFC_PRD_NG[0].id
  }

  tags = {
    Name = "TFC-PRD-Private-RT01"
  }
}
resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.TFC_PRD_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.TFC_PRD_NG[1].id
  }

  tags = {
    Name = "TFC-PRD-Private-RT02"
  }
}

# 프라이빗 서브넷에 라우팅 테이블 연결
resource "aws_route_table_association" "private_a01" {
  subnet_id      = aws_subnet.TFC_PRD_sub[2].id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_b01" {
  subnet_id      = aws_subnet.TFC_PRD_sub[3].id
  route_table_id = aws_route_table.private_b.id
}

resource "aws_route_table_association" "private_a02" {
  subnet_id      = aws_subnet.TFC_PRD_sub[4].id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_b02" {
  subnet_id      = aws_subnet.TFC_PRD_sub[5].id
  route_table_id = aws_route_table.private_b.id
}

# Public Subnet의 라우팅 테이블 생성
resource "aws_route_table" "public_a" {
  vpc_id = aws_vpc.TFC_PRD_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    # nat_gateway_id = aws_nat_gateway.TFC_PRD_NG[0].id
    gateway_id = aws_internet_gateway.TFC_PRD_IG.id
  }

  tags = {
    Name = "TFC-PRD-Public-RT01"
  }
}
resource "aws_route_table" "public_b" {
  vpc_id = aws_vpc.TFC_PRD_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    # nat_gateway_id = aws_nat_gateway.TFC_PRD_NG[1].id
    gateway_id = aws_internet_gateway.TFC_PRD_IG.id
  }

  tags = {
    Name = "TFC-PRD-Public-RT02"
  }
}

# 퍼블릿 서브넷에 라우팅 테이블 연결
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.TFC_PRD_sub[0].id
  route_table_id = aws_route_table.public_a.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.TFC_PRD_sub[1].id
  route_table_id = aws_route_table.public_b.id
}