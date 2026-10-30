# Bloomi — fase móvil de usuarios

## Alcance entregado

La app Flutter tiene dos estados claramente separados. Antes de autenticarse, muestra una bienvenida pública que explica Bloomi y permite registrarse o iniciar sesión; no presenta datos de cuenta, puntos, donaciones ni cuestionario. Después de crear una cuenta o iniciar sesión muestra el área privada con Inicio (perfil, puntos e indicadores), Centros, Canjes e Impacto. La cuenta está integrada en Inicio. El panel para hospitales queda en el producto web.

Flutter consume la API NestJS para autenticación, perfil, centros, donaciones, puntos, recompensas, canjes y cuestionario. Los tokens se guardan con `flutter_secure_storage`; las credenciales privilegiadas solo existen en el servidor. El esquema de `supabase/schema.sql` está aplicado a `bloomi-app`, junto con los registros ficticios de `supabase/seed.sql`. La revisión médica de respuestas sigue a cargo de personal autorizado; no usar datos clínicos reales en el ambiente de desarrollo.

## API y flujo de datos

El backend NestJS está en `backend/`; sus instrucciones están en `backend/README.md`. Flutter se comunica únicamente con NestJS. La API verifica tokens de Supabase Auth y sus consultas de usuario aplican RLS. La app móvil nunca debe incluir la `service_role` key ni conectarse a tablas con privilegios elevados.

### Endpoints implementados en la API inicial

| Método | Ruta | Uso |
|---|---|---|
| GET | `/v1/health` | Comprobar que NestJS inició. |
| POST | `/v1/auth/register` | Registrar email, contraseña y documento declarado; devuelve sesión o aviso de confirmación de correo. |
| POST | `/v1/auth/login` | Iniciar sesión con email y contraseña. |
| POST | `/v1/auth/refresh` | Renovar sesión. |
| POST | `/v1/auth/logout` | Revocar sesión de Supabase Auth. |
| GET/PATCH | `/v1/me` | Consultar/actualizar perfil propio. |
| GET | `/v1/centers?city={city}` | Listar centros publicados. |
| GET | `/v1/me/donations` | Consultar historial propio. |
| GET | `/v1/me/points` | Consultar saldo e historial del libro de puntos. |
| GET | `/v1/rewards` | Listar recompensas disponibles. |
| GET/POST | `/v1/me/redemptions` | Consultar canjes / canjear una recompensa con validación transaccional. |
| GET/POST | `/v1/me/questionnaire` | Consultar preguntas activas / enviar las respuestas propias. |

Los tokens los gestiona Supabase Auth; las contraseñas no se guardan en las tablas de Bloomi. El documento de registro es autodeclarado/no verificado y solo se conserva como HMAC. La app no debe decidir elegibilidad a partir de respuestas: esa decisión corresponde al personal médico.

## Modelo de datos inicial para Supabase/Postgres

- `profiles`: `id` (UUID enlazado al usuario de auth), nombres, apellidos, fecha de nacimiento, género opcional, `blood_type` nullable, dirección opcional, ciudad/departamento y timestamps.
- `identity_documents`: `user_id`, tipo, HMAC único, marca de verificación opcional y fecha; nunca contiene el número original y no es legible por la app.
- `institutions` e `institution_memberships`: organizaciones, estado y usuarios institucionales con rol (`owner`/`admin`/`staff`).
- `health_questionnaire_versions`: `id`, versión, idioma, estado publicado y fecha efectiva.
- `health_questions`: `id`, versión, código estable, texto, categoría, orden, tipo de respuesta, si es obligatoria y si es sensible.
- `health_questionnaire_submissions`: `id`, `user_id`, versión, estado (`draft`/`submitted`/`reviewed`), fecha de envío y revisión.
- `health_questionnaire_answers`: `submission_id`, `question_id`, respuesta, timestamps. Restringir acceso de usuario a sus propios registros y lectura institucional al personal autorizado.
- `donation_centers`: `id`, institución, nombre, dirección, ciudad/departamento, ubicación, contacto, horarios, estado de publicación.
- `donations`: `id`, `user_id`, `center_id`, estado, fecha, referencia externa y timestamps; solo una institución autorizada puede crear/confirmar una donación.
- `points_ledger`: `id`, `user_id`, tipo (`donation`/`redemption`/`adjustment`/`reversal`), cantidad firmada, referencia de donación/canje, actor y fecha. El saldo se calcula desde movimientos; no confiar en un saldo enviado por el cliente.
- `rewards`: `id`, nombre, descripción, costo en puntos, inventario/condiciones, institución aliada y estado de publicación.
- `reward_redemptions`: `id`, `user_id`, `reward_id`, puntos usados, estado, código de reclamación, expiración y timestamps. Crear el canje y el movimiento de ledger atómicamente para evitar doble gasto.

El script habilita RLS y acceso mínimo para todas las tablas. La API aplica RLS en las consultas de usuario. Las respuestas médicas solo son visibles por el dueño; acceso institucional requiere definir consentimiento primero. El esquema también crea un bucket privado de avatares con políticas por carpeta y otro público para imágenes de recompensas.

## Variables para conectar más adelante

La app acepta `BLOOMI_API_BASE_URL` por `--dart-define`; tiene valores por defecto para emulador Android (`10.0.2.2`) y Windows (`localhost`). No guardar secretos en `--dart-define`, assets, repositorio ni builds móviles. Los tokens se almacenan en el almacén seguro del sistema operativo.

## Próximos pasos técnicos

1. Proyecto creado: `bloomi-app`. Ya tiene aplicados `supabase/schema.sql`, índices/políticas revisados y `supabase/seed.sql` con datos ficticios. Para recrear otro ambiente, aplicar esos archivos en orden.
2. Ejecutar NestJS y Flutter en terminales separadas según las instrucciones de `README.md` y validar el registro con una cuenta ficticia.
3. Antes de publicar, configurar un dominio HTTPS, quitar HTTP claro del manifiesto de depuración para builds de producción y revisar consentimiento/retención de datos médicos.
4. Crear el portal web institucional y su autorización antes de dar a hospitales acceso a registros de donantes o cuestionarios.

