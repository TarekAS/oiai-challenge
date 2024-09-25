terraform {
  backend "s3" {
    bucket         = "oiai-prod-terraform-state"
    dynamodb_table = "oiai-prod-terraform-state-lock"
    key            = "oiai/prod/eks/prod1/k8s"
    region         = "eu-west-1"
    encrypt        = true
  }
}

provider "aws" {
  region  = "eu-west-1"
  profile = "oiai-prod-admin"

  default_tags {
    tags = {
      Terraform   = "true"
      Environment = "oiai-prod"
    }
  }
}
