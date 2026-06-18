resource "azurerm_monitor_action_group" "this" {
  count               = var.create_action_group ? 1 : 0
  name                = var.action_group_name
  resource_group_name = var.resource_group_name
  short_name          = var.action_group_short_name
  tags                = var.tags

  dynamic "email_receiver" {
    for_each = var.email_receivers

    content {
      name          = email_receiver.key
      email_address = email_receiver.value
    }
  }

  dynamic "webhook_receiver" {
    for_each = var.webhook_receivers

    content {
      name        = webhook_receiver.key
      service_uri = webhook_receiver.value
    }
  }
}

resource "azurerm_monitor_metric_alert" "this" {
  for_each            = var.metric_alerts
  name                = each.value.name
  resource_group_name = var.resource_group_name
  scopes              = each.value.scopes
  description         = each.value.description
  severity            = each.value.severity
  frequency           = each.value.frequency
  window_size         = each.value.window_size
  enabled             = each.value.enabled
  tags                = var.tags

  criteria {
    metric_namespace = each.value.metric_namespace
    metric_name      = each.value.metric_name
    aggregation      = each.value.aggregation
    operator         = each.value.operator
    threshold        = each.value.threshold
  }

  dynamic "action" {
    for_each = var.create_action_group ? [azurerm_monitor_action_group.this[0].id] : []

    content {
      action_group_id = action.value
    }
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "this" {
  for_each              = var.scheduled_query_alerts
  name                  = each.value.name
  resource_group_name   = var.resource_group_name
  location              = var.location
  scopes                = each.value.scopes
  description           = each.value.description
  severity              = each.value.severity
  evaluation_frequency  = each.value.evaluation_frequency
  window_duration       = each.value.window_duration
  enabled               = each.value.enabled
  skip_query_validation = each.value.skip_query_validation
  tags                  = var.tags

  criteria {
    query                   = each.value.query
    time_aggregation_method = each.value.time_aggregation_method
    metric_measure_column   = each.value.metric_measure_column
    resource_id_column      = each.value.resource_id_column
    operator                = each.value.operator
    threshold               = each.value.threshold

    failing_periods {
      minimum_failing_periods_to_trigger_alert = each.value.failing_periods.minimum_failing_periods_to_trigger_alert
      number_of_evaluation_periods             = each.value.failing_periods.number_of_evaluation_periods
    }

    dynamic "dimension" {
      for_each = each.value.dimensions

      content {
        name     = dimension.value.name
        operator = dimension.value.operator
        values   = dimension.value.values
      }
    }
  }

  dynamic "action" {
    for_each = var.create_action_group ? [azurerm_monitor_action_group.this[0].id] : []

    content {
      action_groups = [action.value]
    }
  }
}
