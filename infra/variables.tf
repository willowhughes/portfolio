variable "domain_name" {
  description = "The main domain name for the portfolio"
  type        = string
}

variable "bucket_name" {
  description = "The name of the S3 bucket (usually matches the domain)"
  type        = string
}

variable "region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}