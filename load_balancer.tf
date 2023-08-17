# Route53에서 존 생성
resource "aws_route53_zone" "aws_devnote_dev_zone" {
  name = "aws.devnote.dev"
}

# ELB에서 트래픽을 전달할 대상 그룹 생성
resource "aws_lb_target_group" "TFC_PRD_TG" {
  name     = "TFC-PRD-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.TFC_PRD_VPC.id

  # 대상 그룹의 헬스 체크 설정
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

# 웹 트래픽을 분산할 애플리케이션 로드 밸런서 생성
resource "aws_lb" "TFC_PRD_ALB" {
  internal           = false
  load_balancer_type = "application"
  name               = "TFC-PRD-ALB"
  security_groups    = [aws_security_group.TFC_PRD_ALB_SG.id]
  subnets            = [aws_subnet.TFC_PRD_sub[0].id, aws_subnet.TFC_PRD_sub[1].id]
  enable_deletion_protection = false
  tags = {
    Name = "TFC-PRD-ALB"
  }
}

# 생성된 ELB에 리스너 추가하고 대상 그룹 연결
resource "aws_lb_listener" "TFC_PRD_Listener_HTTP" {
  load_balancer_arn = aws_lb.TFC_PRD_ALB.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TFC_PRD_TG.arn
  }
}

resource "aws_lb_listener_rule" "TFC_PRD_ListenerRule_Redirect_HTTP" {
  listener_arn = aws_lb_listener.TFC_PRD_Listener_HTTP.arn

  # 리디렉션 설정
  action {
    type = "redirect"

    redirect {
      host        = "#{host}"
      path        = "/Static.html" # 리디렉션 대상 경로 설정
      port        = "80"
      protocol    = "HTTP"
      query       = "#{query}"
      status_code = "HTTP_301" # 301 영구 리디렉션
    }
  }

  # 리디렉션 조건: 루트 경로로의 요청을 리디렉트
  condition {
    path_pattern {
      values = ["/"]
    }
  }
}
resource "aws_lb_listener_rule" "TFC_PRD_ListenerRule_Redirect_HTTPS" {
  listener_arn = aws_lb_listener.TFC_PRD_Listener_HTTPS.arn

  # 리디렉션 설정
  action {
    type = "redirect"

    redirect {
      host        = "#{host}"
      path        = "/Static.html" # 리디렉션 대상 경로 설정
      port        = "443"
      protocol    = "HTTPS"
      query       = "#{query}"
      status_code = "HTTP_301" # 301 영구 리디렉션
    }
  }

  # 리디렉션 조건: 루트 경로로의 요청을 리디렉트
  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

# HTTPS 연결을 위한 SSL/TLS 인증서 생성
resource "aws_acm_certificate" "cert" {
  domain_name       = "aws.devnote.dev"
  validation_method = "DNS"
}

# DNS 방식으로 인증서 검증을 위한 Route53 레코드 생성
resource "aws_route53_record" "cert_validation" {
  zone_id = aws_route53_zone.aws_devnote_dev_zone.zone_id
  name    = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_type
  records = [tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_value]
  ttl     = 60
}

# Route53 레코드를 이용하여 인증서 검증
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}

# Application Load Balancer 수정: HTTPS 리스너 추가
resource "aws_lb_listener" "TFC_PRD_Listener_HTTPS" {
  load_balancer_arn = aws_lb.TFC_PRD_ALB.arn
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
  name    = "cj.aws.devnote.dev"
  type    = "A"

  alias {
    name                   = aws_lb.TFC_PRD_ALB.dns_name
    zone_id                = aws_lb.TFC_PRD_ALB.zone_id
    evaluate_target_health = false
  }
}