variable "cluster_name" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "load_balancer" {
  type = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
