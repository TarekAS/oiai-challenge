# Create a bastion instance to allow access to RDS via SessionManager.
module "bastion" {
  source  = "cloudposse/ec2-bastion-server/aws"
  version = "0.30.1"

  name          = "bastion"
  instance_type = "t3a.micro"

  assign_eip_address = false
  vpc_id             = data.aws_vpc.main.id
  subnets            = data.aws_subnets.main_private.ids
  security_group_rules = concat([for sg in data.aws_security_groups.rds_postgres.ids : {
    type                     = "egress"
    from_port                = 5432
    to_port                  = 5432
    protocol                 = "tcp"
    source_security_group_id = sg
    decription               = "RDS Postgres instances."
    }],
    # SSM VPC endpoint.
    [{
      type                     = "egress"
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = module.vpc_endpoints.security_group_id
      decription               = "Access to VPC Endpoints."
  }])
}
