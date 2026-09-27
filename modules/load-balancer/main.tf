locals {
  name = "${var.project}-${var.environment}"
}

resource "aws_lb" "this" {
  name                       = substr("${local.name}-alb", 0, 32)
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.security_group_id]
  subnets                    = var.public_subnet_ids
  enable_deletion_protection = var.deletion_protection
  drop_invalid_header_fields = true
  idle_timeout               = 60
  tags                       = merge(var.tags, { Name = "${local.name}-alb" })
}

resource "aws_lb_target_group" "ingress" {
  name        = substr("${local.name}-ingress", 0, 32)
  port        = var.target_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  deregistration_delay = 30
  tags                 = merge(var.tags, { Name = "${local.name}-ingress-tg" })
}

resource "aws_lb_target_group_attachment" "ingress" {
  for_each = toset(var.target_ips)

  target_group_arn = aws_lb_target_group.ingress.arn
  target_id        = each.value
  port             = var.target_port
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ingress.arn
  }

  tags = var.tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = var.tags
}
