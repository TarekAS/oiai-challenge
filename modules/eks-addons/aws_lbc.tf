locals {
  aws_lbc_namespace       = "kube-system"
  aws_lbc_service_account = "aws-load-balancer-controller"
}

module "aws_load_balancer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.34.0"

  role_name = "aws-load-balancer-controller-${var.cluster_name}"

  attach_load_balancer_controller_targetgroup_binding_only_policy = true
  load_balancer_controller_targetgroup_arns                       = ["*"]

  oidc_providers = {
    main = {
      provider_arn               = local.oidc_provider_arn
      namespace_service_accounts = ["${local.aws_lbc_namespace}:${local.aws_lbc_service_account}"]
    }
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.7.1"
  namespace  = local.aws_lbc_namespace

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.name"
    value = local.aws_lbc_service_account
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_load_balancer_controller_irsa_role.iam_role_arn
  }
}
