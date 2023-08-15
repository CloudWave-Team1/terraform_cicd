# # Private Subnet의 라우팅 테이블 생성
# resource "aws_route_table" "private_a" {
#   vpc_id = aws_vpc.TFC_PRD_VPC.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.TFC_PRD_NG[0].id
#   }

#   tags = {
#     Name = "TFC-PRD-Private-RT01"
#   }
# }
# resource "aws_route_table" "private_b" {
#   vpc_id = aws_vpc.TFC_PRD_VPC.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.TFC_PRD_NG[1].id
#   }

#   tags = {
#     Name = "TFC-PRD-Private-RT02"
#   }
# }

# # 프라이빗 서브넷에 라우팅 테이블 연결
# resource "aws_route_table_association" "private_a01" {
#   subnet_id      = aws_subnet.TFC_PRD_sub[2].id
#   route_table_id = aws_route_table.private_a.id
# }

# resource "aws_route_table_association" "private_b01" {
#   subnet_id      = aws_subnet.TFC_PRD_sub[3].id
#   route_table_id = aws_route_table.private_b.id
# }

# resource "aws_route_table_association" "private_a02" {
#   subnet_id      = aws_subnet.TFC_PRD_sub[4].id
#   route_table_id = aws_route_table.private_a.id
# }

# resource "aws_route_table_association" "private_b02" {
#   subnet_id      = aws_subnet.TFC_PRD_sub[5].id
#   route_table_id = aws_route_table.private_b.id
# }

# # Public Subnet의 라우팅 테이블 생성
# resource "aws_route_table" "public_a" {
#   vpc_id = aws_vpc.TFC_PRD_VPC.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     # nat_gateway_id = aws_nat_gateway.TFC_PRD_NG[0].id
#     gateway_id = aws_internet_gateway.TFC_PRD_IG.id
#   }

#   tags = {
#     Name = "TFC-PRD-Public-RT01"
#   }
# }
# resource "aws_route_table" "public_b" {
#   vpc_id = aws_vpc.TFC_PRD_VPC.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     # nat_gateway_id = aws_nat_gateway.TFC_PRD_NG[1].id
#     gateway_id = aws_internet_gateway.TFC_PRD_IG.id
#   }

#   tags = {
#     Name = "TFC-PRD-Public-RT02"
#   }
# }

# # 퍼블릿 서브넷에 라우팅 테이블 연결
# resource "aws_route_table_association" "public_a" {
#   subnet_id      = aws_subnet.TFC_PRD_sub[0].id
#   route_table_id = aws_route_table.public_a.id
# }

# resource "aws_route_table_association" "public_b" {
#   subnet_id      = aws_subnet.TFC_PRD_sub[1].id
#   route_table_id = aws_route_table.public_b.id
# }

# 로컬 변수 설정
locals {
  # 프라이빗 서브넷에 대한 설정 정보. 이름, NAT 게이트웨이 인덱스 및 연관된 서브넷들의 리스트를 포함합니다.
  private_subnets = [
    { name = "TFC-PRD-Private-RT01", nat_index = 0, subnets = [2, 4] },
    { name = "TFC-PRD-Private-RT02", nat_index = 1, subnets = [3, 5] }
  ]

  # 퍼블릭 서브넷에 대한 설정 정보. 이름 및 연관된 서브넷들의 리스트만 포함합니다.
  public_subnets = [
    { name = "TFC-PRD-Public-RT01", subnets = [0] },
    { name = "TFC-PRD-Public-RT02", subnets = [1] }
  ]
}

# 프라이빗 서브넷의 라우팅 테이블 생성
# 각 프라이빗 서브넷은 NAT 게이트웨이를 통한 아웃바운드 트래픽을 허용합니다.
resource "aws_route_table" "private" {
  count  = length(local.private_subnets) # private_subnets의 갯수만큼 라우팅 테이블을 생성합니다.
  vpc_id = aws_vpc.TFC_PRD_VPC.id

  route {
    cidr_block      = "0.0.0.0/0"
    nat_gateway_id  = aws_nat_gateway.TFC_PRD_NG[local.private_subnets[count.index].nat_index].id
  }

  tags = {
    Name = local.private_subnets[count.index].name
  }
}

# 각 프라이빗 서브넷에 대한 라우팅 테이블 연결
# 연관된 서브넷들을 해당 라우팅 테이블에 연결합니다.
resource "aws_route_table_association" "private" {
  count          = sum([for subnet in local.private_subnets : length(subnet.subnets)])
  subnet_id      = aws_subnet.TFC_PRD_sub[local.private_subnets[floor(count.index / 2)].subnets[count.index % 2]].id
  route_table_id = aws_route_table.private[floor(count.index / 2)].id
}

# 퍼블릭 서브넷의 라우팅 테이블 생성
# 퍼블릭 서브넷은 인터넷 게이트웨이를 통한 아웃바운드 및 인바운드 트래픽을 허용합니다.
resource "aws_route_table" "public" {
  count  = length(local.public_subnets) # public_subnets의 갯수만큼 라우팅 테이블을 생성합니다.
  vpc_id = aws_vpc.TFC_PRD_VPC.id

  route {
    cidr_block  = "0.0.0.0/0"
    gateway_id  = aws_internet_gateway.TFC_PRD_IG.id
  }

  tags = {
    Name = local.public_subnets[count.index].name
  }
}

# 각 퍼블릭 서브넷에 대한 라우팅 테이블 연결
# 연관된 서브넷들을 해당 라우팅 테이블에 연결합니다.
resource "aws_route_table_association" "public" {
  count          = sum([for subnet in local.public_subnets : length(subnet.subnets)])
  subnet_id      = aws_subnet.TFC_PRD_sub[local.public_subnets[floor(count.index / 1)].subnets[count.index % 1]].id
  route_table_id = aws_route_table.public[floor(count.index / 1)].id
}