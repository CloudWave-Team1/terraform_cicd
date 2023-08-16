# EC2 인스턴스 생성을 위한 템플릿
resource "aws_launch_template" "TFC_EC2_template" {
  description   = "TFC EC2 basic start"
  image_id      = "ami-03ba98da05afd63c6"
  instance_type = "t2.micro"
  name_prefix   = "TFC-EC2-template"
  # user_data = base64encode(file("./userdata.sh")) # 테스트 용

  vpc_security_group_ids = [aws_security_group.TFC_PRD_EC2_SG.id]

  # IAM 역할을 연결
  iam_instance_profile {
    name = "ssmrole"
  }
}