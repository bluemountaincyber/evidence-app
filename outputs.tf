output "website_url" {
  description = "Website URL."
  value       = "https://${aws_cloudfront_distribution.evidence-distribution.domain_name}"
}