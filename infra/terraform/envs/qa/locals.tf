locals {
  resource_prefix = "cerohuella"
  image           = "${var.acr_login_server}/${var.image_repository}:${var.image_tag}"

  database_url = "postgresql+psycopg://${var.postgres_admin_login}:${var.postgres_admin_password}@${module.postgresql.fqdn}:5432/${module.postgresql.database_name}"

  container_app_environment_id = var.create_container_apps_environment ? module.container_apps_environment[0].id : var.existing_container_app_environment_id

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
