## Why

El ambiente `prod` esta definido como pendiente, pero el proyecto necesita una forma academica, minima y reconstruible de demostrar la promocion final sin elevar costos ni exceder cuotas de Azure.

La suscripcion ya mostro una restriccion de cuota para Container Apps Environment en `eastus2`, por lo que aplicar el `prod` actual tal como esta puede fallar o crear recursos mas costosos de lo necesario.

## What Changes

- Ajustar `infra/terraform/envs/prod` para un despliegue academico de bajo costo.
- Reutilizar el Container Apps Environment existente cuando no sea viable crear uno propio para `prod`.
- Mantener aislamiento minimo de `prod` con su propio resource group, PostgreSQL, Container App, Managed Identity, Application Insights, Log Analytics y alertas.
- Configurar compute minimo para `prod`: `0.5 vCPU`, `1Gi`, `min_replicas = 0`, `max_replicas = 1`.
- Mantener el despliegue de `prod` solo por `workflow_dispatch` y environment `prod`; no debe ejecutarse automaticamente desde `main`.
- Documentar el comportamiento esperado y los riesgos academicos aceptados.

## Capabilities

### New Capabilities

- `prod-academico-azure`: Define el comportamiento requerido para crear y operar un ambiente PROD academico, minimo, manual y reconstruible en Azure.

### Modified Capabilities

- Ninguna.

## Impact

- Terraform: `infra/terraform/envs/prod`.
- Documentacion operativa: `docs/arquitectura-azure.md`, `docs/github-azure-cicd.md`, `docs/github-environments-oidc.md`, `tareas.md`, `AGENTS.md`.
- GitHub Actions: se conserva el despliegue manual de `prod`; no se agrega despliegue automatico.
- Azure: creacion futura de recursos `prod` mediante Terraform `workflow_dispatch` o CLI, con costos minimos y sin crear un nuevo Container Apps Environment por defecto.
