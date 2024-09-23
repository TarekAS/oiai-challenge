locals {
  region     = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id

  cluster_endpoint       = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  cluster_token          = data.aws_eks_cluster_auth.this.token

  tags = merge(var.tags, {
    cluster = var.cluster_name
  })

  oidc_issuer_url      = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
  oidc_issuer_hostpath = replace(local.oidc_issuer_url, "https://", "")
  oidc_provider_arn    = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_issuer_hostpath}"
}

provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = local.cluster_ca_certificate
  token                  = local.cluster_token
}

provider "helm" {
  kubernetes {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = local.cluster_ca_certificate
    token                  = local.cluster_token
  }
}

provider "kubectl" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = local.cluster_ca_certificate
  token                  = local.cluster_token
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

data "aws_vpc" "main" {
  tags = {
    Name = var.vpc_name
  }
}

data "aws_lb" "this" {
  name = var.load_balancer
}

data "aws_lb_listener" "selected443" {
  load_balancer_arn = data.aws_lb.this.arn
  port              = 443
}
