# Bloomi API

API REST en NestJS. Arquitectura: Flutter / web de instituciones → NestJS → Supabase Auth y PostgreSQL. Las credenciales privilegiadas y la conexión PostgreSQL solo viven en el servidor.

## Requisitos

- Node.js 20.19 o posterior (el workspace se preparó con Node 24).
- Un proyecto Supabase vacío para Bloomi.
- La migración inicial aplicada antes de iniciar NestJS.

## Preparar Supabase

1. Crea un proyecto nuevo para Bloomi en el Dashboard de Supabase. No uses otro proyecto existente sin confirmar que corresponde a esta app.
2. En **SQL Editor**, abre `../supabase/schema.sql`, revísalo y ejecútalo una sola vez sobre el proyecto vacío. El script crea tablas, restricciones, índices, trigger de perfiles, puntos por donaciones confirmadas, control transaccional de canjes, grants, RLS y buckets privados/públicos para archivos.
3. Opcional: ejecuta `../supabase/seed.sql` para agregar un centro, recompensas y una pregunta totalmente ficticios, útiles para probar GET `/v1/centers`, GET `/v1/rewards` y el cuestionario. No añade donantes ni saldo de puntos. Omite este paso si no quieres registros de prueba.
4. En **Project Settings → API Keys**, copia la URL, la publishable key y una clave `secret`/`service_role`. En **Connect**, copia la cadena del *Transaction Pooler* (puerto 6543) y reemplaza `[YOUR-PASSWORD]`. La clave privilegiada y la contraseña de DB son solo para servidor.
5. En **Authentication → Providers → Email**, decide si se exige confirmar el email. Si se exige, el registro responde `emailConfirmationRequired: true` y el usuario inicia sesión tras confirmar el correo.
6. Copia `.env.example` a `.env` y completa los valores. Nunca publiques `.env` ni pongas `SUPABASE_SERVICE_ROLE_KEY`, `DATABASE_URL` o `DOCUMENT_HMAC_SECRET` en Flutter.

El esquema mantiene solo un HMAC del documento de identidad, no su número en texto. Se usa `DOCUMENT_HMAC_SECRET` para generar ese HMAC. Si se cambia el secreto, los documentos existentes ya no se pueden comparar con nuevos registros: guárdalo en un gestor de secretos y respáldalo.

La conexión PostgreSQL valida el certificado TLS de Supabase usando `certs/supabase-prod-ca-2021.crt`; conserva esa verificación activa. Para otro proyecto, descarga su certificado desde **Database Settings → SSL Configuration** y sustituye el archivo de CA.

## Instalar y ejecutar

```powershell
Copy-Item .env.example .env
# Completa backend/.env con los valores del proyecto Supabase
npm ci
npm run start:dev
```

La API escucha en `http://localhost:3000/v1`. Para probarla desde un emulador Android, usa `http://10.0.2.2:3000/v1`; en un teléfono conectado a la misma red, usa la IP local del computador. Configura ese origen en `CORS_ORIGINS` si lo usas desde la app web institucional.

## Rutas disponibles

| Método | Ruta | Acceso | Función |
|---|---|---|---|
| GET | `/v1/health` | Público | Estado de NestJS |
| POST | `/v1/auth/register` | Público | Registro por correo, contraseña y documento (documento guardado como HMAC) |
| POST | `/v1/auth/login` | Público | Inicio de sesión por correo |
| POST | `/v1/auth/refresh` | Público | Renovar access token |
| POST | `/v1/auth/logout` | Bearer | Revocar sesión de Supabase Auth |
| GET | `/v1/centers?city=Bogotá` | Público | Centros publicados |
| GET | `/v1/rewards` | Público | Recompensas publicadas |
| GET/PATCH | `/v1/me` | Bearer | Leer/actualizar perfil propio |
| GET | `/v1/me/donations` | Bearer | Historial propio |
| GET | `/v1/me/points` | Bearer | Saldo e historial de puntos |
| GET/POST | `/v1/me/redemptions` | Bearer | Ver canjes / canjear una recompensa |
| GET/POST | `/v1/me/questionnaire` | Bearer | Consultar cuestionario activo / enviar respuestas propias |

Todas las rutas privadas verifican el token con Supabase Auth. Las consultas de usuario abren una transacción, cambian al rol Postgres `authenticated`, fijan el `sub` verificado y aplican RLS. Así, el API no usa una consulta global para leer perfiles o respuestas. Las escrituras de documentos de identidad son una operación administrativa aislada durante el registro.

## Probar con PowerShell

```powershell
$base = 'http://localhost:3000/v1'
Invoke-RestMethod "$base/health"

$signup = Invoke-RestMethod -Method Post -Uri "$base/auth/register" -ContentType 'application/json' -Body (@{
  email = 'mateo.prueba@example.com'
  password = 'CambiarEstaClave123!'
  documentType = 'cc'
  documentNumber = '1234567890'
} | ConvertTo-Json)

# Si Supabase requiere confirmación de correo, confirma primero el mensaje.
$login = Invoke-RestMethod -Method Post -Uri "$base/auth/login" -ContentType 'application/json' -Body (@{
  email = 'mateo.prueba@example.com'
  password = 'CambiarEstaClave123!'
} | ConvertTo-Json)
$headers = @{ Authorization = "Bearer $($login.session.accessToken)" }
Invoke-RestMethod "$base/me" -Headers $headers
Invoke-RestMethod "$base/centers"  # lista vacía hasta cargar centros reales
```

El ejemplo usa datos ficticios; no envíes datos médicos reales durante estas primeras pruebas.

Para probar un canje, registra e inicia sesión con una cuenta de prueba, reemplaza el correo de `../supabase/seed-demo-points.sql` por ese correo y ejecútalo en SQL Editor. Ese archivo solo añade 100 puntos ficticios a esa cuenta; no lo uses en producción. El token devuelto por el login va en el encabezado `Authorization: Bearer <accessToken>`.

## Pruebas y limitaciones actuales

`npm test` ejecuta la prueba unitaria de health. Las pruebas contra Supabase requieren credenciales en `.env` y deben usar un proyecto de desarrollo separado. No se incluye servicio web de instituciones todavía; el esquema tiene instituciones, miembros y centros como base del siguiente módulo. El cuestionario no habilita acceso institucional a respuestas médicas; ese permiso requiere un flujo explícito de consentimiento y roles antes de implementarse.

## Apuntes de seguridad

- Activa confirmación de correo para cualquier ambiente que no sea local.
- Configura límites de registro/login en Supabase Auth y límites de solicitudes en el despliegue de NestJS.
- El documento enviado es autodeclarado y no está verificado por una institución.
- `points_ledger` es un libro de movimientos: el usuario solo lo lee; los puntos se generan desde donaciones confirmadas y las recompensas usan una transacción protegida por bloqueo de usuario.
- Las respuestas del cuestionario solo son visibles para su propietario. No guardes información clínica real hasta definir consentimiento, retención y revisión de acceso.

## Recuperación de contraseña

La app ofrece «¿Olvidaste tu contraseña?» en el inicio de sesión. El usuario escribe su correo y ve «Revisa tu correo», con la dirección enviada, instrucciones, reenvío tras 60 segundos y opciones para corregir el correo o volver al inicio de sesión. No se piden códigos ni contraseñas en esta pantalla. El enlace del correo abre un formulario para elegir una contraseña nueva de 10 a 128 caracteres con confirmación. Después del cambio, el usuario vuelve a la app e inicia sesión.

La página raíz de la API también admite los enlaces de recuperación de Supabase: detecta `type=recovery`, muestra un formulario de contraseña nueva y envía el token al endpoint protegido `POST /v1/auth/update-password`. El token se elimina de la dirección del navegador y solo se conserva en memoria. Los enlaces de registro muestran la confirmación de correo; los enlaces vencidos muestran instrucciones para solicitar otro. Configura la Site URL de Supabase con el origen público de esta API (no `localhost` cuando se abre el correo en otro dispositivo).

**Configuración del correo en el proyecto de Supabase:** en Authentication → Email Templates → Reset Password, usa el contenido de `templates/recovery.html` y el asunto «Restablece tu contraseña de Bloomi». La plantilla solo incluye el botón con `{{ .ConfirmationURL }}`. La plantilla predeterminada con enlace también funciona. Configura SMTP para entregar correos a usuarios reales y verifica la caducidad y los límites de envío de Auth.

`POST /v1/auth/forgot-password` es público y recibe `{ email }`. `POST /v1/auth/update-password` recibe `{ password }` y exige una sesión Bearer válida, verificada por AuthGuard con Supabase. El antiguo endpoint por código se eliminó. Nunca se usan permisos administrativos para saltarse la verificación. La solicitud no confirma si el correo está registrado.

Prueba de aceptación: solicita un correo con una cuenta de prueba, abre el enlace más reciente, confirma la nueva contraseña y vuelve a la app para iniciar sesión con ella. Comprueba un enlace vencido, el reenvío y que la contraseña anterior deje de funcionar. Las pruebas unitarias simulan Supabase; no verifican la entrega real del correo.
