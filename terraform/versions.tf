terraform {
  required_version = ">= 1.5"
  required_providers {
    aws     = { source = "hashicorp/aws", version = "~> 5.0" }
    archive = { source = "hashicorp/archive", version = "~> 2.4" }
    random  = { source = "hashicorp/random", version = "~> 3.6" }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = { Project = var.project }
  }
}

# Short random suffix so global names (S3 bucket, Cognito domain) are unique
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
  name         = "${var.project}-${random_string.suffix.result}"
  frontend_dir = "${path.module}/../frontend"
  backend_dir  = "${path.module}/../backend"
  website_url  = "https://${aws_cloudfront_distribution.website.domain_name}"
}
