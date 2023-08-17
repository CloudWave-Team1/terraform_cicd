# Route53에 존 생성
resource "aws_route53_zone" "aws_devnote_dev_zone" {
  name = "aws.devnote.dev"
}

# Target Group 생성: ELB에서 트래픽을 전달할 대상 그룹을 설정합니다.
resource "aws_lb_target_group" "TFC_PRD_TG" {
  name     = "TFC-PRD-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.TFC_PRD_VPC.id

  # 헬스 체크 설정: 대상 그룹에 대한 헬스 체크 설정을 합니다.
  health_check {
    enabled             = true
    interval            = 30
    path                = "/Static.html"
    port                = 80
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "TFC-PRD-TG"
  }
}

# Application Load Balancer 생성: 웹 트래픽을 분산시킬 ELB를 생성합니다.
resource "aws_lb" "TFC_PRD_ELB" {
  internal           = false
  load_balancer_type = "application"
  name               = "TFC-PRD-ELB"
  security_groups    = [aws_security_group.TFC_PRD_ELB_SG.id]
  subnets            = [aws_subnet.TFC_PRD_sub[0].id, aws_subnet.TFC_PRD_sub[1].id]
  enable_deletion_protection = false
  tags = {
    Name = "TFC-PRD-ELB"
  }
}

# ALB 리스너에서 대상 그룹을 default action으로 설정: 생성된 ELB에 리스너를 추가하고 대상 그룹을 연결합니다.
resource "aws_lb_listener" "TFC_PRD_Listener" {
  load_balancer_arn = aws_lb.TFC_PRD_ELB.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TFC_PRD_TG.arn
  }
}

# ACM에서 인증서 생성: HTTPS 연결을 위한 SSL/TLS 인증서를 생성합니다.
resource "aws_acm_certificate" "cert" {
  domain_name       = "www.aws.devnote.dev"
  validation_method = "DNS"
}

# 인증서 검증용 Route53 레코드 생성: DNS 방식으로 인증서를 검증하기 위한 레코드를 Route53에 생성합니다.
resource "aws_route53_record" "cert_validation" {
  zone_id = aws_route53_zone.aws_devnote_dev_zone.zone_id
  name    = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_type
  records = [tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_value]
  ttl     = 60
}

# 인증서 검증: Route53 레코드를 이용하여 인증서를 검증합니다.
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}

# Application Load Balancer 수정: HTTPS 리스너 추가
resource "aws_lb_listener" "TFC_PRD_Listener_HTTPS" {
  load_balancer_arn = aws_lb.TFC_PRD_ELB.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08" # 보안 정책 설정
  certificate_arn   = aws_acm_certificate_validation.cert.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TFC_PRD_TG.arn
  }
}

# ELB에 대한 A 레코드 생성
resource "aws_route53_record" "load_balancer_alias_record" {
  zone_id = aws_route53_zone.aws_devnote_dev_zone.zone_id
  name    = "www.aws.devnote.dev"
  type    = "A"

  alias {
    name                   = aws_lb.TFC_PRD_ELB.dns_name
    zone_id                = aws_lb.TFC_PRD_ELB.zone_id
    evaluate_target_health = false
  }
}