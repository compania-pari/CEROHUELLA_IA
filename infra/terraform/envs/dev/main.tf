module "resource_group" {
  source   = "../../modules/resource_group"
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

module "network" {
  source                         = "../../modules/network"
  virtual_network_name           = var.virtual_network_name
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  address_space                  = var.address_space
  container_apps_subnet_name     = var.container_apps_subnet_name
  container_apps_subnet_prefixes = var.container_apps_subnet_prefixes
  postgresql_subnet_name         = var.postgresql_subnet_name
  postgresql_subnet_prefixes     = var.postgresql_subnet_prefixes
  tags                           = local.common_tags
}

module "log_analytics" {
  source              = "../../modules/log_analytics"
  name                = var.log_analytics_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  retention_in_days   = var.log_retention_days
  tags                = local.common_tags
}

module "application_insights" {
  source              = "../../modules/application_insights"
  name                = var.application_insights_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  workspace_id        = module.log_analytics.id
  tags                = local.common_tags
}

module "container_apps_environment" {
  source                     = "../../modules/container_apps_environment"
  name                       = var.container_apps_environment_name
  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  log_analytics_workspace_id = module.log_analytics.id
  infrastructure_subnet_id   = module.network.container_apps_subnet_id
  tags                       = local.common_tags
}

module "managed_identity" {
  source              = "../../modules/managed_identity"
  name                = var.managed_identity_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  acr_id              = var.acr_id
  tags                = local.common_tags
}

module "postgresql" {
  source                 = "../../modules/postgresql_flexible_server"
  name                   = var.postgresql_server_name
  resource_group_name    = module.resource_group.name
  location               = module.resource_group.location
  postgresql_version     = var.postgresql_version
  delegated_subnet_id    = module.network.postgresql_subnet_id
  virtual_network_id     = module.network.virtual_network_id
  private_dns_zone_name  = var.postgresql_private_dns_zone_name
  administrator_login    = var.postgres_admin_login
  administrator_password = var.postgres_admin_password
  sku_name               = var.postgresql_sku_name
  storage_mb             = var.postgresql_storage_mb
  backup_retention_days  = var.postgresql_backup_retention_days
  database_name          = var.database_name
  tags                   = local.common_tags
}

module "container_app" {
  source                       = "../../modules/container_app"
  name                         = var.container_app_name
  resource_group_name          = module.resource_group.name
  container_app_environment_id = module.container_apps_environment.id
  identity_id                  = module.managed_identity.id
  registry_server              = var.acr_login_server
  image                        = local.image
  cpu                          = var.container_cpu
  memory                       = var.container_memory
  min_replicas                 = var.min_replicas
  max_replicas                 = var.max_replicas
  target_port                  = var.app_port
  tags                         = local.common_tags

  env = {
    APP_NAME                            = var.app_name
    APP_ENV                             = var.environment
    APP_HOST                            = "0.0.0.0"
    APP_PORT                            = tostring(var.app_port)
    GOOGLE_CLOUD_PROJECT_ID             = var.google_cloud_project_id
    GOOGLE_APPLICATION_CREDENTIALS_PATH = var.google_application_credentials_path
    STORAGE_ROOT                        = var.storage_root
    MAX_FILE_SIZE_MB                    = tostring(var.max_file_size_mb)
    MAX_BATCH_FILES                     = tostring(var.max_batch_files)
    OTEL_SERVICE_NAME                   = "cerohuella-api-${var.environment}"
  }

  secrets = {
    "database-url"                          = local.database_url
    "google-application-credentials-b64"    = var.google_application_credentials_b64
    "applicationinsights-connection-string" = module.application_insights.connection_string
  }

  secret_env = {
    DATABASE_URL                          = "database-url"
    GOOGLE_APPLICATION_CREDENTIALS_B64    = "google-application-credentials-b64"
    APPLICATIONINSIGHTS_CONNECTION_STRING = "applicationinsights-connection-string"
  }

  depends_on = [
    module.managed_identity
  ]
}

module "monitor_alerts" {
  source                  = "../../modules/monitor_alerts"
  resource_group_name     = module.resource_group.name
  create_action_group     = var.create_action_group
  action_group_name       = var.action_group_name
  action_group_short_name = var.action_group_short_name
  email_receivers         = var.alert_email_receivers
  webhook_receivers       = var.alert_webhook_receivers
  tags                    = local.common_tags

  metric_alerts = {
    container_cpu_high = {
      name             = "ma-cerohuella-api-${var.environment}-cpu-high"
      scopes           = [module.container_app.id]
      description      = "Container App CPU is above threshold."
      severity         = 3
      metric_namespace = "Microsoft.App/containerApps"
      metric_name      = "CpuPercentage"
      aggregation      = "Average"
      operator         = "GreaterThan"
      threshold        = var.container_cpu_alert_threshold
    }
    postgresql_cpu_high = {
      name             = "ma-cerohuella-postgresql-${var.environment}-cpu-high"
      scopes           = [module.postgresql.id]
      description      = "PostgreSQL CPU is above threshold."
      severity         = 3
      metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
      metric_name      = "cpu_percent"
      aggregation      = "Average"
      operator         = "GreaterThan"
      threshold        = var.postgresql_cpu_alert_threshold
    }
  }
}

