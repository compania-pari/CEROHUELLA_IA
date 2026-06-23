## Context

Cero Huella IA ya cuenta con `shared`, `dev` y `qa` aplicados en Azure mediante Terraform. `dev` despliega desde `develop`; `qa` despliega desde `main`; `prod` quedo pendiente por tiempo y costos.

Durante la aplicacion de `qa`, Azure devolvio una limitacion academica de cuota para Container Apps Environment en `eastus2`. La solucion aplicada en `qa` fue reutilizar el Container Apps Environment de `dev` y conectar la red de `qa` mediante VNet peering y Private DNS link. Ese mismo patron reduce riesgo para `prod`.

## Goals / Non-Goals

**Goals:**

- Habilitar un ambiente `prod` academico, reconstruible y de costo minimo.
- Evitar crear un nuevo Container Apps Environment por defecto para no chocar con cuotas regionales.
- Mantener aislamiento razonable para `prod`: resource group, PostgreSQL, Container App, Managed Identity, Application Insights, Log Analytics y alertas propias.
- Mantener el despliegue de `prod` como accion manual desde GitHub Actions.
- Mantener compatibilidad con Terraform remoto y OIDC GitHub -> Azure.

**Non-Goals:**

- No crear un ambiente productivo empresarial de alta disponibilidad.
- No activar despliegue automatico a `prod` desde `main`.
- No migrar almacenamiento local a Azure Files o Blob Storage en esta etapa.
- No aumentar replicas ni tamano de PostgreSQL por encima del minimo academico.

## Decisions

1. Reutilizar el Container Apps Environment existente por defecto.

   - Decision: agregar a `prod` variables equivalentes a `qa`: `create_container_apps_environment`, `existing_container_app_environment_id`, `shared_container_apps_virtual_network_name` y `shared_container_apps_virtual_network_resource_group_name`.
   - Razon: la suscripcion academica ya mostro una cuota regional que impide crear multiples Container Apps Environment en `eastus2`.
   - Alternativa descartada: crear `cae-cerohuella-prod`; tiene mayor aislamiento, pero puede fallar por cuota y aumenta costos.

2. Mantener PostgreSQL propio para `prod`.

   - Decision: `prod` conserva `psql-cerohuella-prod` y base `cerohuella`.
   - Razon: evita mezclar datos de validacion con datos de demostracion productiva.
   - Alternativa descartada: reutilizar PostgreSQL de `qa`; reduce costo, pero rompe el aislamiento minimo esperado para `prod`.

3. Usar compute minimo.

   - Decision: `container_cpu = 0.5`, `container_memory = "1Gi"`, `min_replicas = 0`, `max_replicas = 1`.
   - Razon: es suficiente para demostracion academica y evita consumo permanente cuando no hay trafico.
   - Alternativa descartada: `min_replicas = 1` y `1 vCPU / 2Gi`; es mas cercano a produccion real, pero mas costoso.

4. Mantener CD de `prod` manual.

   - Decision: conservar `deploy-prod-manual` con `workflow_dispatch`.
   - Razon: evita despliegues productivos accidentales tras merge a `main`.
   - Alternativa descartada: promocionar automaticamente de `qa` a `prod`; no corresponde al alcance academico actual.

## Risks / Trade-offs

- Cuota de Azure Container Apps Environment -> Mitigacion: reutilizar CAE existente y crear VNet peering + Private DNS link para PostgreSQL `prod`.
- Menor aislamiento de plataforma entre `dev`, `qa` y `prod` -> Mitigacion: Container App, PostgreSQL, identidad, observabilidad y secretos siguen separados por ambiente.
- `min_replicas = 0` puede provocar cold start -> Mitigacion: aceptado por costo academico; smoke test valida `/health` tras despliegue.
- Almacenamiento local se pierde ante recreacion o nueva revision -> Mitigacion: documentar riesgo y mantener migracion a Azure Files/Blob como etapa futura.
- Logs de sistema del CAE compartido quedan asociados al workspace del CAE -> Mitigacion: telemetria de aplicacion se envia a Application Insights propio de `prod`.

## Migration Plan

1. Ajustar Terraform de `prod` para soportar reutilizacion de CAE y VNet peering.
2. Reducir defaults de compute de `prod` a valores academicos.
3. Actualizar documentacion y tareas.
4. Validar `terraform fmt`, `terraform validate` y pruebas de aplicacion.
5. Ejecutar `terraform plan`/`apply` de `prod` por GitHub Actions o CLI con backend remoto.
6. Ejecutar CD manual a `prod`.
7. Validar `/health`, Application Insights y Log Analytics.

Rollback:

- Revertir el commit Terraform/documental si aun no se aplico.
- Si se aplico en Azure, ejecutar `terraform destroy` solo para `prod` o eliminar el resource group `rg-cerohuella-prod` con confirmacion explicita.
