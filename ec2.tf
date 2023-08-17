# IAM 역할 생성
resource "aws_iam_role" "ec2_rds_s3_access_ssm_role" {
  name = "EC2_RDS_S3_AccessRole"

  # IAM 역할을 생성하면서, 이 역할을 사용할 수 있는 서비스를 정의합니다.
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Effect = "Allow",
    }]
  })
}

# RDS 전체 접근 권한을 IAM 역할에 연결
resource "aws_iam_role_policy_attachment" "rds_full_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
  role       = aws_iam_role.ec2_rds_s3_access_ssm_role.name
}

# S3 전체 접근 권한을 IAM 역할에 연결
resource "aws_iam_role_policy_attachment" "s3_full_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.ec2_rds_s3_access_ssm_role.name
}

# CodeDeploy 전체 접근 권한을 IAM 역할에 연결
resource "aws_iam_role_policy_attachment" "codedeploy_full_access" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployFullAccess"
  role       = aws_iam_role.ec2_rds_s3_access_ssm_role.name
}

# SSM 전체 접근 권한을 IAM 역할에 연결
resource "aws_iam_role_policy_attachment" "ssm_full_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
  role       = aws_iam_role.ec2_rds_s3_access_ssm_role.name
}

# SSM 관리된 인스턴스 코어 정책을 IAM 역할에 연결
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ec2_rds_s3_access_ssm_role.name
}

# IAM 인스턴스 프로필 생성
resource "aws_iam_instance_profile" "ec2_rds_s3_access_ssm_profile" {
  name = "EC2_RDS_S3_AccessProfile"
  role = aws_iam_role.ec2_rds_s3_access_ssm_role.name
}

# EC2 인스턴스 생성을 위한 템플릿
resource "aws_launch_template" "TFC_EC2_template" {
  description           = "TFC-EC2-basic-start-template"
  image_id              = "ami-0d3120170251f6a8f"
  instance_type         = "t2.micro"
  name_prefix           = "TFC-EC2-basic-start-template"
#   user_data             = base64encode(data.template_file.setup_script.rendered)
  vpc_security_group_ids = [aws_security_group.TFC_PRD_EC2_SG.id]
  user_data             = base64encode(file("./ec2_rds.sh"))

  # 생성한 IAM 인스턴스 프로필을 EC2 인스턴스에 연결
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_rds_s3_access_ssm_profile.name
  }
}