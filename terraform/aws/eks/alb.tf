
# ALB and TargetGroup statically created using terraform. We'll add the targets using TargetGroupBinding.
module "alb_prod_1" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.7.0"

  name    = "prod-1"
  vpc_id  = data.aws_vpc.main.id
  subnets = data.aws_subnets.main_private.ids

  # Security Group
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = data.aws_vpc.main.cidr_block
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
      ssl_policy      = "ELBSecurityPolicy-FS-1-2-Res-2020-10" # Strict SSL policy
      certificate_arn = data.aws_acm_certificate.oiai.arn
      fixed_response = {
        content_type = "text/plain"
        status_code  = "503"
      }
    }
  }
}
