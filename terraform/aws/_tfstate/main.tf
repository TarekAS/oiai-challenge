# oiai Prod
provider "aws" {
  alias   = "oiai-prod"
  profile = "oiai-prod-admin"
  region  = "eu-west-1"
}

# Create S3 bucket for tfstate and DynamoDB table for locking.
module "tfstate_prod" {
  providers = {
    aws = aws.oiai-prod
  }
  source     = "cloudposse/tfstate-backend/aws"
  version    = "1.4.0"
  namespace  = "oiai"
  stage      = "prod"
  name       = "terraform"
  attributes = ["state"]
}
