locals {
  # Append PR suffix to service name if it's a preview environment.
  name              = var.service_name
  target_group_name = var.environment_name == "oiai-sandbox" ? "${local.name}-sandbox" : local.name

  default_tags = {
    Terraform   = "true"
    Environment = var.environment_name
    Service     = var.service_name
  }

  default_labels = merge(local.default_tags, {
    app = local.name
  })

  backendsvc_secrets_version = "AWSCURRENT"

  domain_list = var.environment_name == [
    "${local.name}.oiai.com"
  ]
}

resource "kubernetes_deployment_v1" "this" {
  metadata {
    name        = local.name
    namespace   = var.namespace
    labels      = local.default_labels
    annotations = {}
  }
  spec {
    selector {
      match_labels = {
        app = local.name
      }
    }

    template {
      metadata {
        labels = local.default_labels
      }

      spec {
        node_selector = {}
        container {
          name    = "backendsvc"
          image   = var.image
          args    = []
          command = []

          resources {
            limits = {
              memory            = var.scaling.memory
              ephemeral-storage = var.scaling.ephemeral_storage

            }
            requests = {
              cpu               = var.scaling.cpu
              memory            = var.scaling.memory
              ephemeral-storage = var.scaling.ephemeral_storage

            }
          }

          startup_probe {
            http_get {
              path = "/healthz"
              port = 8080
            }
            initial_delay_seconds = 20
            period_seconds        = 10
            success_threshold     = 1
            failure_threshold     = 10
            timeout_seconds       = 120
          }

          env_from {
            secret_ref {
              name = "backendsvc"
            }
          }
        }
        # Helps spread across multiple nodes.
        topology_spread_constraint {
          max_skew           = 1
          topology_key       = "kubernetes.io/hostname"
          when_unsatisfiable = "ScheduleAnyway"
          label_selector {
            match_labels = {
              app = local.name
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "this" {
  metadata {
    name        = local.name
    namespace   = var.namespace
    labels      = local.default_labels
    annotations = {}
  }
  spec {
    selector = {
      app = local.name
    }
    port {
      port        = 8080
      target_port = 8080
      name        = "http"
    }
  }
}

resource "kubernetes_service_account_v1" "this" {
  metadata {
    name        = local.name
    namespace   = var.namespace
    labels      = local.default_labels
    annotations = {}
  }
}

resource "kubernetes_manifest" "external_secret_backendsvc" {
  manifest = {
    backendsvcVersion = "external-secrets.io/v1beta1"
    kind              = "ExternalSecret"
    metadata = {
      name        = local.name
      namespace   = var.namespace
      labels      = local.default_labels
      annotations = {}
    }
    spec = {
      refreshInterval = "1m"
      secretStoreRef = {
        name = "aws-secretsmanager"
        kind = "ClusterSecretStore"
      }
      target = {
        name           = local.name
        creationPolicy = "Owner"
      }
      dataFrom = [
        {
          extract = {
            key     = data.aws_secretsmanager_secret.this.name
            version = local.backendsvc_secrets_version
          }
        }
      ]
    }
  }
}

data "aws_secretsmanager_secret" "this" {
  name = var.secret_name
}

resource "kubernetes_manifest" "target_group_binding_backendsvc" {
  manifest = {
    backendsvcVersion = "elbv2.k8s.aws/v1beta1"
    kind              = "TargetGroupBinding"
    metadata = {
      name        = local.name
      namespace   = var.namespace
      labels      = local.default_labels
      annotations = {}
    }
    spec = {
      serviceRef = {
        name = local.target_group_name
        port = 8080
      }
      targetGroupARN = aws_lb_target_group.backendsvc.arn
      targetType     = "ip"
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "this" {
  metadata {
    name        = local.name
    namespace   = var.namespace
    labels      = local.default_labels
    annotations = {}
  }

  spec {
    min_replicas = var.scaling.min_pods
    max_replicas = var.scaling.max_pods

    scale_target_ref {
      kind        = "Deployment"
      api_version = "apps/v1"
      name        = local.name
    }

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.scaling.target_cpu_percent
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = var.scaling.target_mem_percent
        }
      }
    }
  }
}

resource "aws_lb_target_group" "backendsvc" {
  name        = local.name
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.main.id

  deregistration_delay = 30

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/healthz"
    port                = "8080"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 10

    matcher = "200"
  }
}

resource "aws_lb_listener_rule" "backendsvc" {
  listener_arn = data.aws_lb_listener.selected443.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backendsvc.arn
  }

  condition {
    host_header {
      values = local.domain_list
    }
  }
}
