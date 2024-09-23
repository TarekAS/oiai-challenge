
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
    - We will split the Terraform code into multiple workspaces to manage different parts of the infrastructure separately. This will organize the code better, make Terraform operations faster, and reduce the blast radius of changes.
    - Workspaces as follows:
      - `terraform/aws/_tfstate` for S3 bucket and DynamoDB table to store the Terraform state.
      - `terraform/aws/network` for the VPC, subnets, route tables, internet gateway, NAT gateway, etc.
      - `terraform/aws/eks/prod1/infra` for the EKS cluster infrastructure.
      - `terraform/aws/eks/prod1/k8s` for provisioning resources within the cluster.
      - `terraform/aws/rds` for the RDS instance.
      - `terraform/aws/services/<service>` for the services.
  - The directory structure (`terraform/aws/<cluster>`) allows for easily adding new clusters to the IaC, while reducing the blast radius of terraform applies to individual clusters.
4. **Describe the solution to automate the microservices deployment and prepare the most important snippets of code/configuration**
    - TODO
5. **Describe the release lifecycle for the different components**
    - TODO
6. **Describe the testing approach for the infrastructure**
    - TODO
7. **Describe the monitoring approach for the solution**
    - TODO
