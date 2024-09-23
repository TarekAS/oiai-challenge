module "eks_prod_1" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.2.1"

  cluster_name    = "prod-1"
  cluster_version = "1.30"

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
  }

  eks_managed_node_group_defaults = {
    ami_type       = "BOTTLEROCKET_x86_64"
    instance_types = ["c7a.large", "c7a.xlarge", "c7a.2xlarge"]
  }

  # Cluster Autoscaler will handle scaling and spreading nodes across AZs.
  eks_managed_node_groups = {
    default-ondemand = {
      name          = "default-ondemand"
      capacity_type = "ON_DEMAND"
      min_size      = 3
      max_size      = 20
      desired_size  = 3
    }
    default-spot = {
      name           = "default-spot"
      instance_types = ["c7a.large", "c7a.xlarge", "c7a.2xlarge"]
      capacity_type  = "SPOT"
      min_size       = 3
      max_size       = 20
      desired_size   = 3
    }
  }

  vpc_id                   = data.aws_vpc.main.id
  subnet_ids               = data.aws_subnets.main_private.ids
  control_plane_subnet_ids = concat(data.aws_subnets.main_private.ids, data.aws_subnets.main_public.ids)
  node_security_group_additional_rules = {
    ingress = {
      type                     = "ingress"
      description              = "From Load Balancer"
      protocol                 = "-1"
      from_port                = 0
      to_port                  = 0
      source_security_group_id = module.alb_prod_1.security_group_id
    }
  }

  enable_cluster_creator_admin_permissions = true
  access_entries                           = {}
}


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
