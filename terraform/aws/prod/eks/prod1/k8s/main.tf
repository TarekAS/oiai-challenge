module "eks_addons" {
  source        = "../../../../../modules/eks-addons"
  cluster_name  = "prod-1"
  load_balancer = "prod-1"
  vpc_name      = "main"
}
