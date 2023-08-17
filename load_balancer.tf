// Route53에서 aws.devnote.dev라는 이름의 도메인을 생성합니다.
resource "aws_route53_zone" "aws_devnote_dev_zone" {
  name = "aws.devnote.dev"
}

// 로드 밸런서의 대상 그룹을 생성합니다. 이름은 TFC-PRD-TG이고, 포트 80에서 HTTP를 사용합니다.
resource "aws_lb_target_group" "TFC_PRD_TG" {
  name     = "TFC-PRD-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.TFC_PRD_VPC.id

  // 대상 그룹의 상태를 확인하는 헬스 체크를 설정합니다.
  health_check {
    enabled             = true
    interval            = 30
    path                = "/Static.html"
    port                = 80
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  // 대상 그룹에 이름 태그를 추가합니다.
  tags = {
    Name = "TFC-PRD-TG"
  }
}

// 어플리케이션 로드 밸런서를 생성합니다. 이름은 TFC-PRD-ALB입니다.
resource "aws_lb" "TFC_PRD_ALB" {
  internal           = false
  load_balancer_type = "application"
  name               = "TFC-PRD-ALB"
  security_groups    = [aws_security_group.TFC_PRD_ALB_SG.id]
  subnets            = [aws_subnet.TFC_PRD_sub[0].id, aws_subnet.TFC_PRD_sub[1].id]
  enable_deletion_protection = false

  // 로드 밸런서에 이름 태그를 추가합니다.
  tags = {
    Name = "TFC-PRD-ALB"
  }
}

// 로드 밸런서의 HTTP 리스너를 생성합니다. 포트 80에서 동작합니다.
resource "aws_lb_listener" "TFC_PRD_Listener_HTTP" {
  load_balancer_arn = aws_lb.TFC_PRD_ALB.arn
  port              = 80
  protocol          = "HTTP"

  // 대상 그룹을 기본 동작으로 설정합니다.
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TFC_PRD_TG.arn
  }
}

// HTTP 리스너의 리디렉션 규칙을 생성합니다.
resource "aws_lb_listener_rule" "TFC_PRD_ListenerRule_Redirect_HTTPS" {
  listener_arn = aws_lb_listener.TFC_PRD_Listener_HTTPS.arn

  // 리디렉션 동작을 설정합니다.
  action {
    type = "redirect"

    redirect {
      host        = "#{host}"
      path        = "/Static.html"
      port        = "443"
      protocol    = "HTTPS"
      query       = "#{query}"
      status_code = "HTTP_301"
    }
  }

  // 경로 패턴 조건을 설정합니다.
  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

// cj.aws.devnote.dev 도메인의 ACM 인증서를 생성합니다.
resource "aws_acm_certificate" "cert" {
  domain_name       = "cj.aws.devnote.dev"
  validation_method = "DNS"

  subject_alternative_names = [
    aws_lb.TFC_PRD_ALB.dns_name
  ]
}

// 인증서의 DNS 검증 레코드를 생성합니다.
resource "aws_route53_record" "cert_validation" {
  zone_id = aws_route53_zone.aws_devnote_dev_zone.zone_id
  name    = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_type
  records = [tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_value]
  ttl     = 60
}

// ACM 인증서의 검증을 수행합니다.
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}

// 로드 밸런서의 HTTPS 리스너를 생성합니다. 포트 443에서 동작합니다.
resource "aws_lb_listener" "TFC_PRD_Listener_HTTPS" {
  load_balancer_arn = aws_lb.TFC_PRD_ALB.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.cert.certificate_arn

  // 대상 그룹을 기본 동작으로 설정합니다.
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TFC_PRD_TG.arn
  }
}

// cj.aws.devnote.dev 도메인의 A 레코드를 생성하고 로드 밸런서의 앨리어스를 설정합니다.
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