# EC2 오토스케일링 그룹 설정
resource "aws_autoscaling_group" "TFC_PRD_ASG" {
  desired_capacity     = 2
  max_size             = 10
  min_size             = 2
  vpc_zone_identifier  = [aws_subnet.TFC_PRD_sub[2].id, aws_subnet.TFC_PRD_sub[3].id]
  target_group_arns    = [aws_lb_target_group.TFC_PRD_TG.arn]
  launch_template {
    id      = aws_launch_template.TFC_EC2_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "TFC-PRD-EC2"
    propagate_at_launch = true
  }
}

# # Target Tracking Scaling Policy
# resource "aws_autoscaling_policy" "TFC_PRD_ASG_Policy" {
#   name                   = "TFC-PRD-ASG-Policy"
#   autoscaling_group_name = aws_autoscaling_group.TFC_PRD_ASG.name
#   policy_type            = "TargetTrackingScaling"

#   target_tracking_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "ASGAverageNetworkIn"
#     }
#     target_value = 50.0
#   }
# }

# # Target Tracking Scaling Policy
# resource "aws_autoscaling_policy" "TFC_PRD_ASG_Policy" {
#   name                   = "TFC-PRD-ASG-Policy"
#   autoscaling_group_name = aws_autoscaling_group.TFC_PRD_ASG.name
#   policy_type            = "TargetTrackingScaling"

#   target_tracking_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "ASGAverageCPUUtilization"
#     }
#     target_value = 50.0
#   }
# }

resource "aws_autoscaling_policy" "TFC_PRD_ASG_Policy" {
  name                   = "TFC-PRD-ASG-Policy"
  autoscaling_group_name = aws_autoscaling_group.TFC_PRD_ASG.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    customized_metric_specification {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      statistic   = "Sum"
      dimensions {
        name  = "LoadBalancer"
        value = aws_lb.TFC_PRD_ALB.arn # 이 부분을 자신의 로드 밸런서 ARN으로 변경하세요
      }
      unit = "Count"
    }
    target_value = 1000.0 # ALB 요청 수 목표값
  }
}