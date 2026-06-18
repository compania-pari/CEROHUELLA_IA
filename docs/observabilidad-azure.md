# Observabilidad Azure - Cero Huella IA

## Objetivo

Implementar una observabilidad inicial usando servicios nativos de Azure para Cero Huella IA. Esta etapa prioriza una base simple y operable: logs de contenedor, trazas y metricas de aplicacion, metricas de plataforma y alertas basicas.

## Alcance

- Azure Monitor como plano central de observabilidad.
- Log Analytics Workspace por ambiente.
- Application Insights por ambiente, enlazado al workspace.
- Azure Container Apps conectado a Log Analytics.
- Alertas metricas para Container App y PostgreSQL.
- Alertas KQL para requests, errores, excepciones y eventos de contenedor.

No se despliegan Prometheus, Grafana, Loki ni Jaeger en esta etapa. Esas herramientas quedan como posible evolucion cuando el proyecto requiera dashboards mas avanzados, retencion especializada o trazabilidad distribuida fuera de Azure Monitor.

## Recursos por ambiente

| Recurso | Nombre |
| --- | --- |
| Log Analytics Workspace | `law-cerohuella-{env}` |
| Application Insights | `appi-cerohuella-{env}` |
| Container Apps Environment | `cae-cerohuella-{env}` |
| Container App | `ca-cerohuella-api-{env}` |
| PostgreSQL Flexible Server | `psql-cerohuella-{env}` |

Terraform crea estos recursos en `infra/terraform/envs/dev`, `qa` y `prod`.

## Variables de aplicacion

Terraform inyecta:

| Variable | Origen |
| --- | --- |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | Secret de Container App con el connection string de Application Insights. |
| `OTEL_SERVICE_NAME` | Variable de entorno, con formato `cerohuella-api-{env}`. |

La aplicacion debe activar OpenTelemetry solo cuando exista `APPLICATIONINSIGHTS_CONNECTION_STRING`. Esta parte se implementa como cambio de aplicacion en la Fase 11.

## Alertas iniciales

### Alertas metricas

| Alerta | Recurso | Metrica |
| --- | --- | --- |
| CPU alta API | Container App | `CpuPercentage` |
| Memoria alta API | Container App | `MemoryPercentage` |
| CPU alta PostgreSQL | PostgreSQL Flexible Server | `cpu_percent` |
| Storage alto PostgreSQL | PostgreSQL Flexible Server | `storage_percent` |
| Conexiones altas PostgreSQL | PostgreSQL Flexible Server | `active_connections` |

### Alertas KQL

| Alerta | Tabla esperada | Condicion |
| --- | --- | --- |
| API no saludable | `AppRequests` | `/health` falla o responde 5xx. |
| HTTP 5xx | `AppRequests` | Cantidad de 5xx supera el umbral. |
| Latencia alta | `AppRequests` | Promedio de `DurationMs` supera el umbral. |
| Excepciones | `AppExceptions` | Existe al menos una excepcion. |
| Reinicios/crashes | `ContainerAppSystemLogs_CL` | Logs contienen reinicios, backoff o crash loop. |

Las reglas usan `skip_query_validation = true` para permitir crear la infraestructura antes de que las tablas tengan datos.

## Consultas KQL iniciales

### Requests recientes

```kql
AppRequests
| order by TimeGenerated desc
| project TimeGenerated, Name, Url, ResultCode, Success, DurationMs
| take 50
```

### Errores HTTP 5xx

```kql
AppRequests
| where toint(ResultCode) >= 500
| summarize Count = count() by bin(TimeGenerated, 5m), ResultCode
| order by TimeGenerated desc
```

### Latencia promedio

```kql
AppRequests
| summarize AvgDurationMs = avg(DurationMs), P95DurationMs = percentile(DurationMs, 95) by bin(TimeGenerated, 5m)
| order by TimeGenerated desc
```

### Excepciones

```kql
AppExceptions
| order by TimeGenerated desc
| project TimeGenerated, Type, OuterMessage, OperationName, AppRoleName
| take 50
```

### Logs de contenedor

```kql
ContainerAppConsoleLogs_CL
| where ContainerAppName_s startswith "ca-cerohuella-api-"
| order by TimeGenerated desc
| project TimeGenerated, ContainerAppName_s, RevisionName_s, Log_s
| take 100
```

### Reinicios y errores de plataforma

```kql
ContainerAppSystemLogs_CL
| where ContainerAppName_s startswith "ca-cerohuella-api-"
| where Log_s has_any ("Restart", "restarted", "CrashLoopBackOff", "Back-off", "Error")
| order by TimeGenerated desc
| project TimeGenerated, ContainerAppName_s, RevisionName_s, Log_s
```

## Notificacion de alertas

El modulo `monitor_alerts` permite crear un Action Group opcional:

- `create_action_group = true`
- `alert_email_receivers = { operaciones = "equipo@example.com" }`
- `alert_webhook_receivers = {}`

La decision de canal final queda pendiente: correo, webhook, Teams u otro mecanismo operativo.

## Validacion operativa

1. Ejecutar `terraform apply` del ambiente.
2. Desplegar la aplicacion con el workflow CD.
3. Validar `/health`.
4. Revisar `AppRequests` y `ContainerAppConsoleLogs_CL` en Log Analytics.
5. Confirmar que las reglas de alerta quedan creadas en Azure Monitor.

