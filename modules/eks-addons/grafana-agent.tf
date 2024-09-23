resource "kubernetes_namespace" "observability" {
  metadata {
    name = "observability"
  }
}

# https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/README.md
# Install the grafana agent required to forward prom metrics, loki logs, and tempo traces to grafana cloud.
resource "helm_release" "grafana_agent" {
  name       = "grafana-k8s-monitoring"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "k8s-monitoring"
  version    = "0.13.1"
  namespace  = kubernetes_namespace.observability.metadata[0].name

  set {
    name  = "cluster.name"
    value = var.cluster_name
  }

  # Prometheus
  set {
    name  = "externalServices.prometheus.host"
    value = "PLACEHOLDER"
  }

  set {
    name  = "externalServices.prometheus.basicAuth.username"
    value = "PLACEHOLDER"
  }

  set {
    name  = "externalServices.prometheus.basicAuth.password"
    value = jsondecode(data.aws_secretsmanager_secret_version.grafana_cloud_access_policy_token.secret_string)["password"]
  }

  # Loki
  set {
    name  = "externalServices.loki.host"
    value = "PLACEHOLDER"
  }

  set {
    name  = "externalServices.loki.basicAuth.username"
    value = "PLACEHOLDER"
  }

  set {
    name  = "externalServices.loki.basicAuth.password"
    value = jsondecode(data.aws_secretsmanager_secret_version.grafana_cloud_access_policy_token.secret_string)["password"]
  }

  # Tempo
  set {
    name  = "externalServices.tempo.host"
    value = "PLACEHOLDER"
  }

  set {
    name  = "externalServices.tempo.basicAuth.username"
    value = "PLACEHOLDER"
  }

  set {
    name  = "externalServices.tempo.basicAuth.password"
    value = jsondecode(data.aws_secretsmanager_secret_version.grafana_cloud_access_policy_token.secret_string)["password"]
  }

  set {
    name  = "traces.enabled"
    value = true
  }

  set {
    name  = "receivers.zipkin.enabled"
    value = true
  }
}

data "aws_secretsmanager_secret" "grafana_cloud_access_policy_token" {
  name = "grafana-cloud-access-policy-token"
}

data "aws_secretsmanager_secret_version" "grafana_cloud_access_policy_token" {
  secret_id = data.aws_secretsmanager_secret.grafana_cloud_access_policy_token.id
}
