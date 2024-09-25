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
