# Bloomi — app móvil

App Flutter para donantes. La app móvil cubre la experiencia del usuario; la gestión de instituciones y hospitales se trabajará en una aplicación web separada.

En el mismo workspace, `backend/` contiene la API NestJS y `supabase/` contiene el esquema inicial y datos ficticios opcionales para pruebas.

## Organización del código

```text
lib/
├── main.dart                 # Punto de entrada
├── app/                      # MaterialApp, tema aplicado y navegación principal
├── core/                     # Tema, colores y widgets reutilizables
└── features/                 # Código agrupado por funcionalidad
    ├── auth/presentation/    # Registro e inicio de sesión
    ├── home/presentation/    # Inicio
    ├── centers/presentation/ # Centros de donación
    ├── impact/presentation/  # Impacto e historial futuro
    ├── profile/
    │   ├── data/             # Contrato y repositorio HTTP del perfil
    │   ├── domain/           # Modelo UserProfile
    │   └── presentation/     # Cuenta integrada y formulario de datos
    ├── questionnaire/
        ├── data/             # Repositorio HTTP y preguntas de respaldo
        ├── domain/           # Modelo HealthQuestion
        └── presentation/     # Cuestionario
    └── rewards/
        ├── data/             # Catálogo y saldo temporal de demostración
        ├── domain/           # Modelo Reward
        └── presentation/     # Catálogo de canjes
```

Las pantallas se mantienen dentro de su feature. Los modelos viven en `domain`; el acceso a datos va detrás de repositorios en `data`. `ApiClient` centraliza las llamadas HTTP, renueva tokens vencidos y conserva access/refresh tokens en almacenamiento seguro del dispositivo. Las contraseñas y claves privilegiadas nunca se guardan en Flutter.

## Identidad visual

La interfaz conserva la paleta original de SangreVital (`#DC3545`, `#C82333`, `#F8D7DA`) con fondos cálidos y superficies claras. La navegación usa una barra inferior flotante con desenfoque y transparencia.

Antes de iniciar sesión, la app muestra una bienvenida pública que explica cómo funciona Bloomi y ofrece registrarse o iniciar sesión. El panel privado y la navegación flotante (Inicio, Centros, Canjes e Impacto) solo aparecen después de entrar. La sección de cuenta está integrada dentro de Inicio.

## Estado de esta fase

La app se conecta a la API NestJS para registro/inicio de sesión, perfil, centros, historial de donaciones, puntos, canjes y cuestionario. El backend guarda la información en Supabase y valida la sesión antes de acceder a datos privados. El registro pide confirmar el correo si esa opción está activa en Supabase Auth.

Consulta [docs/user-phase.md](docs/user-phase.md) para el contrato sugerido de NestJS y el modelo inicial de Supabase.

El backend inicial está en [backend/README.md](backend/README.md). El esquema de referencia está en [supabase/schema.sql](supabase/schema.sql); ya fue aplicado al proyecto Supabase `bloomi-app` y los registros ficticios de [supabase/seed.sql](supabase/seed.sql) quedaron cargados para pruebas.

## Ejecutar en desarrollo

Abre dos terminales desde la carpeta raíz del proyecto. Primero enciende la API (requiere `backend/.env` configurado):

```powershell
cd backend
npm run start:dev
```

En la segunda terminal, instala paquetes e inicia Flutter:

```sh
flutter pub get
flutter run
```

La URL predeterminada funciona en el emulador Android (`10.0.2.2`) y en Windows/escritorio (`localhost`). En VS Code selecciona el dispositivo y presiona F5. Para un teléfono físico, conecta computador y teléfono a la misma red y reemplaza `192.168.1.20` por la IP local del computador:

```powershell
flutter run --dart-define=BLOOMI_API_BASE_URL=http://192.168.1.20:3000/v1
```

La opción de tráfico HTTP sin TLS está habilitada solo en el manifiesto Android de depuración para permitir la API local. Para publicar la app configura un dominio HTTPS y retira esa excepción de desarrollo.

En Windows, si Flutter indica que los plugins necesitan soporte para enlaces simbólicos, activa **Developer Mode** en Configuración de Windows y vuelve a ejecutar `flutter pub get`.

En Supabase, los usuarios nuevos deben completar su perfil después de registrarse. Las recompensas y centros requieren estar publicados/activos. Para probar canjes, carga saldo ficticio solo en una cuenta de prueba con `supabase/seed-demo-points.sql`.

La pantalla de bienvenida es pública y no muestra datos personales. No uses información médica real durante pruebas; el cuestionario es sensible y la revisión de elegibilidad corresponde al personal de la institución.
