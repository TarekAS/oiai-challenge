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

# ALB and TargetGroup statically created using terraform. We'll add the targets using TargetGroupBinding.
module "alb_prod_1" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.7.0"

  name    = "prod-1"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  # Security Group
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  listeners = {
    http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    https = {
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = "ELBSecurityPolicy-FS-1-2-Res-2020-10"
      certificate_arn = data.aws_acm_certificate.oiai.arn
      fixed_response = {
        content_type = "text/plain"
        status_code  = "503"
      }
    }
  }
}
