output "website_url" {
  description = "Open this in your browser"
  value       = local.website_url
}

output "api_url" {
  value = "${trimsuffix(aws_apigatewayv2_stage.default.invoke_url, "/")}/api/vehicles"
}

output "cognito_login_domain" {
  value = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.region}.amazoncognito.com"
}

output "cloudfront_distribution_id" {
  description = "Needed for a cache invalidation after website changes"
  value       = aws_cloudfront_distribution.website.id
}

output "bucket_name" {
  value = aws_s3_bucket.website.id
}
