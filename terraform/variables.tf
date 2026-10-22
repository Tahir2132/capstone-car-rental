variable "region" {
  description = "AWS region for the S3 bucket"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Globally unique name for the website bucket"
  type        = string
  default     = "capston-rent-website-tf-navid"
}
