# Contains boilerplate code: backend, versions, providers, and supporting data sources.
terraform {
  backend "s3" {}

  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = local.cluster_ca_certificate
  token                  = local.cluster_token
}

provider "aws" {
  region = "eu-west-1"
  default_tags {
    tags = local.default_tags
  }
}

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
    Name = "main"
  }
}

data "aws_lb" "this" {
  name = var.load_balancer
}

data "aws_lb_listener" "selected443" {
  load_balancer_arn = data.aws_lb.this.arn
  port              = 443
}
