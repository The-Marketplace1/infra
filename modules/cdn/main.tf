################################################################################
# CDN Module — CloudFront + ACM + Route53
################################################################################

locals {
  name = "${var.project}-${var.environment}"
}

################################################################################
# ACM Certificate (must be in us-east-1 for CloudFront)
################################################################################
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

resource "aws_acm_certificate" "this" {
  provider          = aws.us_east_1
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = concat(
    ["*.${var.domain_name}"],
    var.additional_domains
  )

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, { Name = local.name })
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.this.zone_id
}

resource "aws_acm_certificate_validation" "this" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

################################################################################
# Route53
################################################################################
data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false
}

################################################################################
# CloudFront Distribution (static assets / CDN)
################################################################################
resource "aws_cloudfront_origin_access_control" "this" {
  name                              = local.name
  description                       = "OAC for ${local.name} S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${local.name} CDN"
  default_root_object = "index.html"
  price_class         = var.price_class
  aliases             = ["cdn.${var.domain_name}"]

  origin {
    domain_name              = var.s3_bucket_domain
    origin_id                = "s3-attachments"
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-attachments"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    cache_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6"  # CachingOptimized
    origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"  # CORS-S3Origin
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.this.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  web_acl_id = var.waf_web_acl_arn

  tags = merge(var.tags, { Name = local.name })

  depends_on = [aws_acm_certificate_validation.this]
}

################################################################################
# Route53 records
################################################################################
resource "aws_route53_record" "cdn" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "cdn.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "root" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

