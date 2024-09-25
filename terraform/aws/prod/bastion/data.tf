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

# Gets the security group of all postgres DBs.
data "aws_security_groups" "rds_postgres" {
  tags = {
    "RDS" = "postgres"
  }
}
