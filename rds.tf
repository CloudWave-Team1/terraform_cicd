# RDS 인스턴스 생성
resource "aws_db_instance" "aws_rds" {
  allocated_storage    = 20          # 할당될 스토리지 크기를 20GB로 설정
  storage_type         = "gp2"       # 스토리지 유형을 일반용 SSD(gp2)로 설정
  engine               = "mysql"     # 데이터베이스 엔진을 MySQL로 설정
  engine_version       = "5.7"       # 데이터베이스 엔진 버전을 5.7로 설정
  instance_class       = "db.t2.micro" # RDS 인스턴스 유형을 db.t2.micro로 설정
  name                 = "sample"      # 데이터베이스 이름을 "sample"로 설정
  username             = var.AWS_RDS_ID # 마스터 사용자 이름을 변수에서 가져옴
  password             = var.AWS_RDS_PASSWORD # 마스터 비밀번호를 변수에서 가져옴
  parameter_group_name = "default.mysql5.7" # 파라미터 그룹을 default.mysql5.7로 설정
  skip_final_snapshot  = true         # RDS 인스턴스 삭제 시 마지막 스냅샷 생성을 건너뜀
}

# RDS 인스턴스 정보를 파일로 저장
output "rds_instance_info" {
  value = {
    endpoint   = aws_db_instance.default.endpoint # RDS 인스턴스의 엔드포인트
    username   = aws_db_instance.default.username # RDS 인스턴스의 마스터 사용자 이름
    port       = aws_db_instance.default.port     # RDS 인스턴스의 포트
    instance_class = aws_db_instance.default.instance_class # RDS 인스턴스 유형
  }
  sensitive = true # 이 정보는 민감한 정보로 처리
}

resource "local_file" "rds_output" {
  content = jsonencode({ # JSON 형식으로 인코딩
    endpoint      = aws_db_instance.default.endpoint, # RDS 인스턴스의 엔드포인트
    username      = aws_db_instance.default.username, # RDS 인스턴스의 마스터 사용자 이름
    port          = aws_db_instance.default.port,     # RDS 인스턴스의 포트
    instance_class = aws_db_instance.default.instance_class # RDS 인스턴스 유형
  })
  filename = "${path.module}/rds_instance_info.json" # 파일 이름 및 경로 설정
}