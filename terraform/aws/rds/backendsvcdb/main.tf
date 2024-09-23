module "rds_backendsvc" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.5.2"

  identifier = "backendsvcdb"

  engine               = "postgres"
  engine_version       = "16"
  family               = "postgres16"
  major_engine_version = "16"
  instance_class       = "db.t4g.micro"
  allocated_storage    = 10

  username = "postgres"
  port     = "5432"

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  monitoring_interval    = "0"
  create_monitoring_role = false

  vpc_security_group_ids              = [aws_security_group.rds_backendsvc.id]
  subnet_ids                          = data.aws_subnets.main_private.ids
  create_db_subnet_group              = true
  iam_database_authentication_enabled = true
  deletion_protection                 = true

  tags = {
    Service = "backendsvc"
  }
}

resource "aws_security_group" "rds_backendsvc" {
  name        = "rds-backendsvc-sg"
  description = "Security group for Postgres access to RDS backendsvc"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = concat(data.aws_security_groups.eks.ids, data.aws_security_groups.bastion.ids)
  }

  tags = {
    Name    = "rds-backendsvc-sg"
    Service = "backendsvc"
    RDS     = "postgres"
  }
}
