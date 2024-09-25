
# Open Innovation AI DevOps Challenge

This challenge is to implement a platform top support a microservices architecture composed of a backend service, frontend service and
PostgreSQL database with the following requirements:
- Automated Deployment
- Fault Tolerant / Highly Available
- Secure
- Autoscaling

## Architecture Decisions
1. **Choose the infrastructure platform to use**
    - We will go with **AWS** for the following reasons:
      - Familiarity/experience with AWS more than any other platform.
      - AWS is easily automatable (Terraform AWS provider is very mature and stable).
      - AWS allows us to more easily meet high availability, fault-tolerance, scalability, and security requirements.
    - We will rely on the following AWS services:
      - **Elastic Kubernetes Service (EKS)** as managed-kubernetes, for the orchestration of the microservices.
      - **EC2** for the compute nodes used by the EKS cluster.
      - **Elastic Load Balancer (ELB)** for exposing services.
      - **RDS** for the PostgreSQL database.
      - And other supporting services such as **VPC**, **IAM**, **Route53**, **CloudWatch**, etc.
2. **Choose the orchestration technology and their components**
    - We will go with **Kubernetes** for the following reasons:
      - Kubernetes skill is in-demand, and the job description asks for it.
      - Although Kubernetes is overkill for the task at hand, it will allow me to more effectively demonstrate my capabilities.
      - Most companies are moving to Kubernetes, so the availability of engineers that know how to use it is increasing.
      - Kubernetes has a huge ecosystem of tools and services surrounding it that can be taken advantage of.
      - Kubernetes lets us do difficult things more easily (high availability, autoscaling, automation), at the high upfront cost of additional complexity.
      - Ideal for microservice architectures and cloud-native applications.
    - It has the following compononets:
      - Control Plane (EKS-managed): apiserver, controller-manager, scheduler, etcd.
      - Worker Nodes (EC2): kubelet, kube-proxy, container runtime.
3. **Describe the solution to automate the infrastructure deployment and prepare the most important snippets of code/configuration**
    - To automate the infrastructure deployment, we will use **Terraform**.
    - We will split the Terraform infra code into multiple workspaces to manage different parts of the infrastructure separately. This will organize the code better, make Terraform operations faster, and reduce the blast radius of changes.
    - Workspaces as follows:
      - `terraform/aws/_tfstate` for S3 bucket and DynamoDB table to store the Terraform state.
      - `terraform/aws/network` for the VPC, subnets, route tables, internet gateway, NAT gateway, etc.
      - `terraform/aws/eks/prod1/infra` for the EKS cluster infrastructure.
      - `terraform/aws/eks/prod1/k8s` for provisioning resources within the cluster.
      - `terraform/aws/rds` for the RDS instance.
      - `terraform/aws/bastion` for the SSM bastion to be used to securly connect to DBs in private subnets.
  - The directory structure (`terraform/aws/<cluster>`) allows for easily adding new clusters to the IaC, while reducing the blast radius of terraform applies to individual clusters.

This deploys a new EKS cluster.
```terraform
# terraform/aws/prod/eks/prod1/infra
module "eks_prod_1" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.2.1"

  cluster_name    = "prod-1"
  cluster_version = "1.30"
...
}
```
This bootstraps the EKS cluster.
```terraform
# terraform/aws/prod/eks/prod1/k8s
module "eks_addons" {
  source        = "../../../../../modules/eks-addons"
  cluster_name  = "prod-1"
  load_balancer = "prod-1"
  vpc_name      = "main"
  ...
}
```

4. **Describe the solution to automate the microservices deployment and prepare the most important snippets of code/configuration**
    - The directory `services/<service>/terraform` contains the service-level resources.
      - This directory contains the high level resources required by the service itself, such as Kubernetes resources (Deployment, Service, etc.) and any necessary high-level AWS resources (SQS queues, SNS topics, etc.).
      - These resources share the same lifecycle of the service itself, and are therefore deployed using the CI/CD pipeline (github actions).
      - This is why they are in the same parent directory of the application code itself. This code is owned by the service owners, not the infra teams.
      - This terraform code is not wrapped into a Terraform module in order not to prematurely abstract it and to allow more flexibility and transparency to the end user.

The Terraform configuration responsible for configuring the application code deployments:
```terraform
# services/backend/terraform/main.tf
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
          image   = var.image # This is set by GitHub Actions
          args    = []
          command = []
...
}
```
It is built and deployed by the GitHub Actions CI workflow, which sets the correct enviornment variables on apply.
```yaml
# .github/workflows/deploy.yml
- name: Terraform Init
  run: |
    # Dynamically determine terraform state backend based on service name and environment.
    terraform init \
      -backend-config="encrypt=true" \
      -backend-config="bucket=${{ vars.TFSTATE_BUCKET }}-terraform-state" \
      -backend-config="key=services/${{ vars.TFSTATE_KEY }}" \
      -backend-config="dynamodb_table=${{ vars.TFSTATE_BUCKET }}-terraform-state-lock"

- name: Terraform Validate
  run: terraform validate -no-color

- name: Terraform Apply
  env:
    TF_VAR_image: REDACTED.dkr.ecr.eu-west-1.amazonaws.com/${{ vars.SERVICE_NAME }}:${{ github.sha }}
  run: terraform apply -lock=false -auto-approve -input=false -var-file=tfvars/${{ vars.TF_VARS_FILE }}
```

5. **Describe the release lifecycle for the different components**
    - Services (backendsvc, frontendsvc)
      - The service resources (i.e. kubernetes manfiests) share the same lifecyle as the code itself, and is deployed using the GitHub Actions pipeline.
      - Since the Kubernetes Deployment manifest is part of the Terraform code, deploying it leads to the deployment of any new versions of the service.
    - Infra/DB
      - Deployed via manual `terraform apply`.
      - Uses the local aws profile for authentication.
      - If infra code CI is needed in the future, I would connect the repo to Terraform Cloud to automate the deployments.
6. **Describe the testing approach for the infrastructure**
    - Testing infrastructure code itself would be done via deploying to a pre-prod environment first (e.g. by creating new infra in `terraform/aws/dev`).
    - Testing Kubernetes cluster upgrades, or a new version of any critical component within, is done by spinning up a new Kubernetes cluster (e.g. `terraform/aws/prod/eks/prod2`), testing it either manually or via a test suite (like kuberhealthy). If it is acceptable, replace the existing cluster with it, either by changing ALB targetgroup, or Route53 weighted routing (not shown here).
    - Terraform unit tests can also be implemented on frequently used and actively maintained modules (not shown here).
7. **Describe the monitoring approach for the solution**
    - Decision is to use 3rd party observability provider Grafana Cloud for the following reasons:
      - Prometheus-based monitoring tools work best with Kubernetes
      - Grafana Cloud relies on open-source components, so switching back to self-managed observability stack is easy if ever needed (e.g. costs or data residency concerns).
      - Grafana dashboards are cool. Community/official dashboard templates are available for almost anything designed to be deployed on kubernetes.
    - How the monitoring solution works:
      - Grafana Agent (deployed as helm chart) collects metrics/logs/traces and forwards them to grafana cloud.
      - There, I would build dashboards around the infra that combine all this data.
      - I would invest time writing Alerts/Pages and routing them to the correct OnCall team.
