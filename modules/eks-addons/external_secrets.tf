locals {
  external_secrets_namespace       = "kube-system"
  external_secrets_service_account = "external-secrets"
}

module "external_secrets_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.34.0"

  role_name = "external-secrets-${var.cluster_name}"

  attach_external_secrets_policy = true

  oidc_providers = {
    main = {
      provider_arn               = local.oidc_provider_arn
      namespace_service_accounts = ["${local.external_secrets_namespace}:${local.external_secrets_service_account}"]
    }
  }
}

resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.9.13"
  namespace  = local.external_secrets_namespace

  set {
    name  = "serviceAccount.name"
    value = local.external_secrets_service_account
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.external_secrets_irsa_role.iam_role_arn
  }
}

resource "kubectl_manifest" "external_secret_cluster_store" {
  depends_on = [helm_release.external_secrets]
  yaml_body  = <<-EOF
  apiVersion: external-secrets.io/v1beta1
  kind: ClusterSecretStore
  metadata:
    name: aws-secretsmanager
  spec:
    provider:
      aws:
        service: SecretsManager
        region: ${local.region}
    EOF
}
