# Standard VPC architecture with 3 private, 3 public subnets spread across the 3 AZs.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.1"

  name = "main"
  cidr = "10.1.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  public_subnets  = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]

  enable_nat_gateway = true

  public_subnet_tags = {
    # Requried for Load Balancer Controller
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    # Requried for Load Balancer Controller
    "kubernetes.io/role/internal-elb" = "1"
  }
}
