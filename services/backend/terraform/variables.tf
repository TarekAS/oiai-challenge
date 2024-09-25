variable "cluster_name" {
  type = string
}

variable "service_name" {
  type = string
}

variable "secret_name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "environment_name" {
  type = string
}

variable "scaling" {
  type = object({
    # Min and Max number of Pods in the autoscaler.
    min_pods = number
    max_pods = number

    # CPU/Memory percent thershold for autoscaling.
    target_cpu_percent = number
    target_mem_percent = number

    cpu               = number # CPU coresper pod.
    memory            = string # Memory per pod
    ephemeral_storage = string # Ephemeral Memory per pod

  })
  default = {
    min_pods           = 1
    max_pods           = 1
    target_cpu_percent = 80
    target_mem_percent = 80
    cpu                = 1
    memory             = "2Gi"
    ephemeral_storage  = "2Gi"

  }
  description = "Parameters used for configuring pod scalability and resource utilization."
}

variable "environment_subdomain" {
  type = string
}

variable "image" {
  type = string
}


variable "load_balancer" {
  type = string
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}
