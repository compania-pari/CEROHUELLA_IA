locals {
  resource_prefix = "cerohuella"
  image           = "${var.acr_login_server}/${var.image_repository}:${var.image_tag}"

  database_url = "postgresql+psycopg://${var.postgres_admin_login}:${var.postgres_admin_password}@${module.postgresql.fqdn}:5432/${module.postgresql.database_name}"

  common_tags = merge(
    {
      project     = "cerohuella-ia"
      environment = var.environment
      managedBy   = "terraform"
      repository  = "compania-pari/CEROHUELLA_IA"
      owner       = var.owner
      costCenter  = var.cost_center
      workload    = "api-redaccion-pdf"
    },
    var.extra_tags
  )
}

