terraform {
  backend "s3" {
    bucket         = "marketplace-tfstate-development"
    key            = "marketplace/development/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "marketplace-tfstate-lock-development"
    encrypt        = true
  }
}

