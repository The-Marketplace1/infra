output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.this.id
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.this.domain_name
}

output "acm_certificate_arn" {
  value = aws_acm_certificate.this.arn
}

output "route53_zone_id" {
  value = data.aws_route53_zone.this.zone_id
}

