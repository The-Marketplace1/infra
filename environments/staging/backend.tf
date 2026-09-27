terraform {
  backend "s3" {
    bucket         = "marketplace-tfstate-staging"
    key            = "marketplace/staging/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "marketplace-tfstate-lock-staging"
    encrypt        = true
  }
}

