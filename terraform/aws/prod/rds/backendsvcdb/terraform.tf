terraform {
  backend "s3" {
    profile        = "oiai-dev-admin"
    bucket         = "oiai-dev-terraform-state"
    dynamodb_table = "oiai-dev-terraform-state-lock"
    key            = "oiai/dev/rds"
    region         = "eu-west-1"
    encrypt        = true
  }
}

provider "aws" {
  region  = "eu-west-1"
  profile = "oiai-dev-admin"

  default_tags {
    tags = {
      Terraform   = "true"
      Environment = "oiai-dev"
    }
  }
}

data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["main"]
  }
}

data "aws_subnets" "main_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  tags = {
    "Name" = "main-private-*"
  }
}

# This security group created by the EKS cluster.
data "aws_security_groups" "eks" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  tags = {
    "Name" = "prod-1-node"
  }
}

data "aws_security_groups" "bastion" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  tags = {
    "Name" = "bastion"
  }
}
