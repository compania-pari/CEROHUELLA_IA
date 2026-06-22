## ADDED Requirements

### Requirement: PROD academico usa costo minimo
El ambiente `prod` SHALL usar configuracion de compute minima para fines academicos y SHALL evitar consumo permanente cuando no haya trafico.

#### Scenario: Terraform define recursos minimos
- **WHEN** se valide la configuracion Terraform de `prod`
- **THEN** la Container App de `prod` tendra `0.5` vCPU, `1Gi` de memoria, `min_replicas = 0` y `max_replicas = 1`

### Requirement: PROD no crea CAE nuevo por defecto
El ambiente `prod` SHALL reutilizar un Container Apps Environment existente por defecto para evitar exceder cuotas academicas de Azure.

#### Scenario: Reutilizacion de CAE
- **WHEN** `create_container_apps_environment` sea `false`
- **THEN** Terraform SHALL usar `existing_container_app_environment_id` para crear la Container App de `prod`

### Requirement: PROD mantiene aislamiento operativo minimo
El ambiente `prod` SHALL mantener recursos propios para datos, identidad, observabilidad y aplicacion aunque reutilice el Container Apps Environment.

#### Scenario: Recursos propios de PROD
- **WHEN** se aplique Terraform de `prod`
- **THEN** se crearan o mantendran resource group, PostgreSQL, Container App, Managed Identity, Application Insights, Log Analytics y alertas con nombres de ambiente `prod`

### Requirement: PROD despliega solo manualmente
El despliegue de `prod` SHALL ejecutarse solo mediante `workflow_dispatch` y environment `prod`.

#### Scenario: Merge a main no despliega PROD
- **WHEN** se realice un merge a `main`
- **THEN** el CD no ejecutara despliegue automatico hacia `prod`

#### Scenario: Workflow manual despliega PROD
- **WHEN** se ejecute manualmente el workflow CD con `environment = prod`
- **THEN** GitHub Actions construira la imagen, actualizara `ca-cerohuella-api-prod` y validara `/health`

### Requirement: PROD conserva observabilidad propia
El ambiente `prod` SHALL enviar telemetria de aplicacion a su propia instancia de Application Insights y SHALL contar con alertas basicas.

#### Scenario: Telemetria de PROD
- **WHEN** la API de `prod` atienda solicitudes
- **THEN** la telemetria de aplicacion se enviara a `appi-cerohuella-prod`
