locals {
  # One database and role per service on a single instance; the env prefix is the service's own.
  databases = {
    commerce            = { name = "commerce", env_prefix = "COMMERCE" }
    entitlement         = { name = "entitlement", env_prefix = "ENTITLEMENT" }
    plant-care          = { name = "plant_care", env_prefix = "PLANT_CARE" }
    expert-consultation = { name = "expert_consultation", env_prefix = "EXPERT_CONSULTATION" }
  }

  rds_master_username = "growpath_admin"
}

# No special characters: the passwords go into URLs unescaped.
resource "random_password" "rds_master" {
  length  = 32
  special = false
}

resource "random_password" "database" {
  for_each = local.databases

  length  = 32
  special = false
}

module "rds_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 6.0"

  name        = "growpath-rds"
  description = "PostgreSQL for the services"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    from_nodes = {
      description                  = "PostgreSQL from the pods"
      referenced_security_group_id = module.eks.node_security_group_id
      from_port                    = 5432
      to_port                      = 5432
    }
    from_tailscale_router = {
      description = "PostgreSQL from the Tailscale router"
      cidr_ipv4   = local.network_vpc_cidr
      from_port   = 5432
      to_port     = 5432
    }
  }
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 7.2"

  identifier = var.cluster_name

  engine               = "postgres"
  engine_version       = "16.16"
  family               = "postgres16"
  major_engine_version = "16"
  instance_class       = "db.t4g.micro"

  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp3"

  username                    = local.rds_master_username
  password_wo                 = random_password.rds_master.result
  password_wo_version         = 1
  manage_master_user_password = false

  create_db_subnet_group = true
  subnet_ids             = module.vpc.private_subnets
  vpc_security_group_ids = [module.rds_sg.id]

  multi_az            = false
  publicly_accessible = false

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled = false
  monitoring_interval          = 0
}

module "database_secret" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "~> 2.2"

  for_each = local.databases

  name                    = "${var.cluster_name}/${each.key}"
  description             = "Environment of the ${each.key} service"
  recovery_window_in_days = 0
  ignore_secret_changes   = true

  secret_string = jsonencode({
    "${each.value.env_prefix}_DATABASE_URL" = format(
      "postgresql+psycopg://%s:%s@%s:%d/%s?sslmode=require",
      each.value.name,
      random_password.database[each.key].result,
      module.rds.db_instance_address,
      module.rds.db_instance_port,
      each.value.name,
    )
  })
}

# Read by the one-off Job that creates the databases and roles; Terraform has no allowed provider for it.
module "rds_bootstrap_secret" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "~> 2.2"

  name                    = "${var.cluster_name}/rds-bootstrap"
  description             = "Admin login and role passwords for the database bootstrap Job"
  recovery_window_in_days = 0
  ignore_secret_changes   = true

  secret_string = jsonencode(merge(
    {
      PGHOST     = module.rds.db_instance_address
      PGPORT     = tostring(module.rds.db_instance_port)
      PGUSER     = local.rds_master_username
      PGPASSWORD = random_password.rds_master.result
      PGDATABASE = "postgres"
    },
    { for key, db in local.databases : "${db.env_prefix}_PASSWORD" => random_password.database[key].result },
  ))
}
