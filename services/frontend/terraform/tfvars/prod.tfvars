service_name     = "frontendsvc"
secret_name      = "frontendsvc"
namespace        = "frontendsvc"
environment_name = "prod"
cluster_name     = "prod-1"
load_balancer    = "prod-1"

scaling = {
  min_pods           = 3
  max_pods           = 10
  target_cpu_percent = 80
  target_mem_percent = 80
  cpu                = 0.5
  memory             = "500Mi"
  ephemeral_storage  = "1Gi"
}
