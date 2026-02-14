terraform {
  backend "s3" {
    bucket         = "willow-portfolio-tf-state"
    key            = "state/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
