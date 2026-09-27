output "waf_web_acl_arn" {
  description = "WAF WebACL ARN for CloudFront"
  value       = aws_wafv2_web_acl.cloudfront.arn
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = aws_guardduty_detector.this.id
}

