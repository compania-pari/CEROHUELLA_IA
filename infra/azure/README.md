# Scripts Azure

Scripts de apoyo para recrear o reconfigurar la infraestructura Azure de CeroHuella IA.

## Orden sugerido

```text
create-resources.ps1
configure-containerapp.ps1
create-devops-service-connection.ps1
create-devops-release.ps1
```

## Seguridad

No colocar secretos reales dentro de estos scripts. Usar parametros, variables de entorno o secretos del servicio.

Secretos que nunca deben commitearse:

- `DATABASE_URL`
- Password de PostgreSQL
- JSON de Google Cloud
- `GOOGLE_APPLICATION_CREDENTIALS_B64`
- Secret de Service Principal
- Tokens de Azure DevOps
