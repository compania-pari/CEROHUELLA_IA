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

