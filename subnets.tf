# 6개의 서브넷 생성 설정
resource "aws_subnet" "TFC_PRD_sub" {
  count = 6

  availability_zone = [var.ap_northeast_2a, var.ap_northeast_2c][count.index % 2]
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