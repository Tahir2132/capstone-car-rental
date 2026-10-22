# Capston Rent – website on S3 + CloudFront (HTTPS, private bucket with OAC)

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  website_dir = "${path.module}/../frontend"

  content_types = {
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    jpg  = "image/jpeg"
    jpeg = "image/jpeg"
    png  = "image/png"
    webp = "image/webp"
  }
}

# 1. S3 bucket for the website files (private)
resource "aws_s3_bucket" "website" {
  bucket        = var.bucket_name
  force_destroy = true # lets "terraform destroy" delete the bucket with its files
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket                  = aws_s3_bucket.website.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 2. Upload every file from ../frontend (HTML, CSS, JS, images)
resource "aws_s3_object" "files" {
  for_each = fileset(local.website_dir, "**")

  bucket       = aws_s3_bucket.website.id
  key          = each.value
  source       = "${local.website_dir}/${each.value}"
  etag         = filemd5("${local.website_dir}/${each.value}")
  content_type = lookup(local.content_types, lower(reverse(split(".", each.value))[0]), "application/octet-stream")
}

# 3. CloudFront with Origin Access Control (only CloudFront may read the bucket)
resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "${var.bucket_name}-oac"
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
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# 4. Bucket policy: allow only this CloudFront distribution to read the files
data "aws_iam_policy_document" "website" {
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
  policy     = data.aws_iam_policy_document.website.json
  depends_on = [aws_s3_bucket_public_access_block.website]
}
