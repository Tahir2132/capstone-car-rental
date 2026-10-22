# ---------- S3: website files and car photos (private) ----------
resource "aws_s3_bucket" "website" {
  bucket        = "${local.name}-website"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket                  = aws_s3_bucket.website.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

locals {
  content_types = {
    html = "text/html", css = "text/css", js = "application/javascript",
    jpg  = "image/jpeg", jpeg = "image/jpeg", png = "image/png", webp = "image/webp"
  }
  # all files in ../frontend except placeholders
  frontend_files = [for f in fileset(local.frontend_dir, "**") : f if !endswith(f, ".gitkeep")]
}

resource "aws_s3_object" "frontend" {
  for_each     = toset(local.frontend_files)
  bucket       = aws_s3_bucket.website.id
  key          = each.value
  source       = "${local.frontend_dir}/${each.value}"
  etag         = filemd5("${local.frontend_dir}/${each.value}")
  content_type = lookup(local.content_types, lower(reverse(split(".", each.value))[0]), "application/octet-stream")
}

# config.js tells the website the API URL and Cognito settings
resource "aws_s3_object" "config" {
  bucket        = aws_s3_bucket.website.id
  key           = "config.js"
  content_type  = "application/javascript"
  cache_control = "no-cache"
  content       = <<-JS
    window.CAPSTON_CONFIG = {
      apiUrl: "${trimsuffix(aws_apigatewayv2_stage.default.invoke_url, "/")}",
      cognitoDomain: "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.region}.amazoncognito.com",
      cognitoClientId: "${aws_cognito_user_pool_client.web.id}"
    };
  JS
}

# ---------- CloudFront with Origin Access Control ----------
resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "${local.name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  comment             = "Capston Rent website"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "s3-website"
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-website"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
    compress               = true
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Only this CloudFront distribution may read the bucket
data "aws_iam_policy_document" "website_bucket" {
  statement {
    sid       = "AllowCloudFrontRead"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.website.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "website" {
  bucket     = aws_s3_bucket.website.id
  policy     = data.aws_iam_policy_document.website_bucket.json
  depends_on = [aws_s3_bucket_public_access_block.website]
}
