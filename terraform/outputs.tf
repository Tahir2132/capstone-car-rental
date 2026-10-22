output "website_url" {
  description = "Open this in your browser"
  value       = "https://${aws_cloudfront_distribution.website.domain_name}"
}

output "bucket_name" {
  value = aws_s3_bucket.website.id
}
