# PostgreSQL y migraciones - Cero Huella IA

## Objetivo

Definir como se provisiona PostgreSQL y como se ejecutan migraciones Alembic en la nueva arquitectura GitHub + Terraform + Azure.

## Provisionamiento

PostgreSQL se provisiona con Terraform, usando el modulo:

```text
infra/terraform/modules/postgresql_flexible_server
```

Cada ambiente tiene su propio servidor:

| Ambiente | Servidor | Base de datos |
| --- | --- | --- |
| `dev` | `psql-cerohuella-dev` | `cerohuella` |
| `qa` | `psql-cerohuella-qa` | `cerohuella` |
| `prod` | `psql-cerohuella-prod` | `cerohuella` |

La decision de servidor por ambiente evita que pruebas o migraciones de `dev` y `qa` afecten `prod`.

## Red

La base de datos se define con acceso privado:

- `public_network_access_enabled = false`.
- Subnet delegada a `Microsoft.DBforPostgreSQL/flexibleServers`.
- Private DNS Zone por ambiente.
- Link DNS hacia la VNet del ambiente.
- Container Apps Environment integrado a la VNet del ambiente.

Esto evita abrir PostgreSQL a Internet. La API accede a PostgreSQL desde Container Apps por red privada.

## Secretos

El password administrador no se versiona.

Terraform espera:

```hcl
postgres_admin_password = "<postgres-admin-password>"
```

solo en archivos reales no versionados, variables de entorno o secretos del pipeline.

Los archivos `*.tfvars.example` contienen placeholders y no secretos reales.

## DATABASE_URL

Terraform compone `DATABASE_URL` como secreto de Container App:

```text
postgresql+psycopg://<admin-user>:<password>@<postgres-fqdn>:5432/cerohuella
```

En la Container App se expone como:

```text
DATABASE_URL=secretref:database-url
```

La aplicacion no debe recibir el password como variable plana.

## Migraciones Alembic

Comando de migracion:

```bash
alembic upgrade head
```

No ejecutar migraciones desde Terraform. Terraform debe crear infraestructura, no aplicar cambios de esquema de aplicacion.

## Decision operativa

Como PostgreSQL sera privado, un runner hospedado por GitHub no tendra conectividad directa hacia la base de datos. Por ello, las migraciones deben ejecutarse desde Azure, dentro del alcance de red del ambiente.

Opcion recomendada para el pipeline:

1. Construir y publicar imagen Docker en ACR.
2. Crear o actualizar un Azure Container Apps Job por ambiente para migraciones.
3. Ejecutar el job con la misma imagen de la API y comando:

   ```bash
   alembic upgrade head
   ```

4. Usar los mismos secretos de la API:
   - `DATABASE_URL`
   - `GOOGLE_CLOUD_PROJECT_ID` si fuese requerido por importacion de settings.
   - `GOOGLE_APPLICATION_CREDENTIALS_B64` si la inicializacion de la app lo requiere.

5. Si la migracion falla, detener la promocion del despliegue.

## Politica por ambiente

| Ambiente | Ejecucion propuesta |
| --- | --- |
| `dev` | Automatica luego de Terraform/apply o antes del despliegue de la nueva revision. |
| `qa` | Manual/aprobada como parte de la promocion desde `main`. |
| `prod` | Manual/aprobada, con revision previa del plan de migracion. |

## Rollback

Alembic permite downgrade si las migraciones lo implementan, pero el rollback automatico de datos no debe asumirse.

Antes de migraciones en `prod`:

- Confirmar backup automatico activo en PostgreSQL Flexible Server.
- Revisar migraciones pendientes con:

  ```bash
  alembic current
  alembic history
  ```

- Validar que la migracion fue probada en `dev` y `qa`.

## Riesgos residuales

- Los runners GitHub no pueden conectarse directamente a una base privada sin red dedicada.
- Si se decide abrir acceso publico temporalmente para migraciones, debe quedar documentado como excepcion y cerrarse despues.
- `DATABASE_URL` puede quedar en el estado Terraform como valor sensible; tratar el backend remoto como informacion sensible.
- Cambios destructivos en migraciones requieren revision manual.

