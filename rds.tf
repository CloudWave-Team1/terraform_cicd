# DB 서브넷 그룹 생성
resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "my-aurora-subnet-group" # 서브넷 그룹 이름 설정
  subnet_ids = [aws_subnet.TFC_PRD_sub[4].id, aws_subnet.TFC_PRD_sub[5].id] # 여기서 4와 5는 TFC-PRD-sub-pri-03과 TFC-PRD-sub-pri-04의 인덱스입니다.

  tags = { # 태그 설정
    Name = "my-aurora-subnet-group" # 이름 태그 설정
  }
}

# Aurora 클러스터 생성
resource "aws_rds_cluster" "aws_aurora" {
  cluster_identifier      = "aurora-cluster" # 클러스터 식별자 설정
  engine                  = "aurora-mysql" # 엔진을 Aurora MySQL로 설정
  engine_version          = "5.7.mysql_aurora.2.03.2" # 엔진 버전을 5.7로 설정
  db_subnet_group_name    = aws_db_subnet_group.aurora_subnet_group.name # 서브넷 그룹을 설정
  master_username         = var.AWS_RDS_ID # 마스터 사용자 이름을 변수에서 가져옴
  master_password         = var.AWS_RDS_PASSWORD # 마스터 비밀번호를 변수에서 가져옴
  backup_retention_period = 7 # 백업 보존 기간 설정
  skip_final_snapshot     = true # 삭제 시 마지막 스냅샷 생성을 건너뜀
  database_name           = "sample" # 생성될 데이터베이스 이름을 "sample"로 설정
  multi_az                = true # Oracle은 multi-az를 지원하지 않습니다. 이 경우에는 true로 설정합니다.
}

# Aurora 클러스터 인스턴스 생성
resource "aws_rds_cluster_instance" "aws_aurora_instance" {
  count              = 2 # 두 개의 클러스터 인스턴스를 생성
  identifier         = "aurora-instance-${count.index + 1}" # 인스턴스 식별자 설정
  cluster_identifier = aws_rds_cluster.aws_aurora.cluster_identifier # Aurora 클러스터를 참조
  instance_class     = "db.t2.micro" # RDS 인스턴스 유형을 db.t2.micro로 설정
  engine             = "aurora-mysql" # 엔진을 Aurora MySQL로 설정
}

# RDS 인스턴스 정보를 파일로 저장 (비활성화됨)
# output "rds_instance_info" {
#   value = {
#     endpoint       = aws_db_instance.aws_rds.endpoint # RDS 인스턴스의 엔드포인트
#     username       = aws_db_instance.aws_rds.username # RDS 인스턴스의 마스터 사용자 이름
#     port           = aws_db_instance.aws_rds.port     # RDS 인스턴스의 포트
#     instance_class = aws_db_instance.aws_rds.instance_class # RDS 인스턴스 유형
#   }
#   sensitive = true # 이 정보는 민감한 정보로 처리
# }

# RDS 인스턴스 정보를 JSON 파일로 저장 (비활성화됨)
# resource "local_file" "rds_output" {
#   content = jsonencode({ # JSON 형식으로 인코딩
#     endpoint      = aws_db_instance.aws_rds.endpoint # RDS 인스턴스의 엔드포인트
#     username      = aws_db_instance.aws_rds.username # RDS 인스턴스의 마스터 사용자 이름
#     port          = aws_db_instance.aws_rds.port     # RDS 인스턴스의 포트
#     instance_class = aws_db_instance.aws_rds.instance_class # RDS 인스턴스 유형
#   })
#   filename = "${path.module}/rds_instance_info.json" # 파일 이름 및 경로 설정
# }