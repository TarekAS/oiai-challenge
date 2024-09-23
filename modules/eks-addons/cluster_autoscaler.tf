locals {
  cluster_autoscaler_namespace       = "kube-system"
  cluster_autoscaler_service_account = "cluster-autoscaler"
}

module "cluster_autoscaler_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.34.0"

  role_name = "cluster-autoscaler-${var.cluster_name}"

  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [var.cluster_name]

  oidc_providers = {
    main = {
      provider_arn               = local.oidc_provider_arn
      namespace_service_accounts = ["${local.cluster_autoscaler_namespace}:${local.cluster_autoscaler_service_account}"]
    }
  }
}

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.35.0"
  namespace  = local.cluster_autoscaler_namespace

  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "awsRegion"
    value = local.region
  }

  set {
    name  = "rbac.serviceAccount.name"
    value = local.cluster_autoscaler_service_account
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.cluster_autoscaler_irsa_role.iam_role_arn
  }
}
