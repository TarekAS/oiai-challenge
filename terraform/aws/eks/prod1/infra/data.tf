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

data "aws_subnets" "main_public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  tags = {
    "Name" = "main-public-*"
  }
}

data "aws_acm_certificate" "oiai" {
  domain      = "oiai.com"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}
