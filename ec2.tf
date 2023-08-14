# EC2 인스턴스 생성을 위한 템플릿
resource "aws_launch_template" "TFC_EC2_template" {
  description   = "TFC EC2 basic start"
  image_id      = "ami-055179a7fc9fb032d"
  instance_type = "t2.micro"
  name_prefix   = "TFC-EC2-template"
  user_data = base64encode(file("./userdata.sh")) # 테스트 용

  vpc_security_group_ids = [aws_security_group.TFC_PRD_EC2_SG.id]
}