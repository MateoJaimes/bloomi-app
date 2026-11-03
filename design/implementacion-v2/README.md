# Bloomi · implementación de los mockups

Capturas renderizadas con Flutter a partir del código de la app. Los datos son
fixtures de prueba; las pantallas de producción usan los repositorios existentes.
Las ilustraciones 3D de la propuesta se sustituyeron por iconos 2D.

| Vista | Captura |
| --- | --- |
| 01 Bienvenida | [Abrir](01-bienvenida.png) |
| 02 Iniciar sesión | [Abrir](02-login.png) |
| 03 Crear cuenta | [Abrir](03-registro.png) |
| 04 Recuperar acceso | [Abrir](04-recuperar.png) |
| 05 Datos personales | [Abrir](05-datos-personales.png) |
| 06 Ficha médica | [Abrir](06-ficha-medica.png) |
| 07 Cuestionario | [Abrir](07-cuestionario.png) |
| 08 Correo enviado | [Abrir](08-correo-enviado.png) |
| 09 Inicio | [Abrir](09-inicio.png) |
| 10 Centros | [Abrir](10-centros.png) |
| 11 Asistente | [Abrir](11-asistente.png) |
| 12 Canjes | [Abrir](12-canjes.png) |
| 13 Impacto | [Abrir](13-impacto.png) |
| 14 Confirmación de canje | [Abrir](14-confirmar-canje.png) |

Sistema visual: rojo #DC3545, fondo #FFF9FA, rosa #FAD9DF, menta #DDF3EA,
lavanda #EEE7FA y amarillo #FFF0CC, con Nunito e iconos locales.

Se conservan la cápsula de cinco destinos, el estado de las pestañas, el
comportamiento con scroll y los bordes de blur progresivo. Las cabeceras rojas
usan ondas dibujadas en Flutter y contornos vectoriales, sin imágenes de fondo.
Los formularios mantienen validación y persistencia; cada paso conserva su
propia posición de scroll. El cuestionario restaura respuestas guardadas y la
confirmación de canje usa una hoja inferior con saldo calculado del repositorio.

Validación: 16 pruebas Flutter, con anchos 320/390/1024 en las pestañas y
320/768/1440 en bienvenida, texto ampliado, teclado simulado, guardado de datos,
recuperación y canje. Compilación web verificada. Android e iOS físicos no se
han ejecutado en esta sesión.

Para regenerar las capturas:

    flutter test --dart-define=BLOOMI_CAPTURE_DESIGN=true

Las capturas de las pestañas también se guardan en `design/sleek/implemented-*.png`.
