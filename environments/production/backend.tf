terraform {
  backend "s3" {
    bucket         = "marketplace-tfstate-production"
    key            = "marketplace/production/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "marketplace-tfstate-lock-production"
    encrypt        = true
  }
}

