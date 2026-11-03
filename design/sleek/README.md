# Bloomi · diseño móvil

Propuesta creada con la skill design-mobile-apps y Sleek.
Proyecto: https://sleek.design/project/Aq8n82wHKNE

## Implementación

- Flutter existente; navegación y repositorios conservados.
- Rojo principal #DC3545, rojo oscuro #C82333, tinta #2B3648,
  fondo #F7F8FA, rosa #FBECEE y borde #E3E6EC.
- Nunito local; iconos exactos de las familias indicadas en los HTML.
- Inicio, Centros, Canjes e Impacto comparten cabecera y navegación.
- Los datos de los HTML son ilustrativos. La app utiliza sus repositorios.
- La búsqueda de centros filtra datos ya cargados; errores permiten reintentar.
- El historial muestra instituciones y fechas devueltas por el servicio,
  sin atribuir puntos a una donación cuando esa relación no está disponible.
- El SVG floral conserva su geometría y gradientes; se omiten únicamente
  los filtros de desenfoque que flutter_svg no admite. El original queda aquí.

## Artefactos

Los HTML y `*-user.png` son la propuesta de Sleek. Los `*-review.png`
permiten revisar el contenido completo. `implemented-*.png` son capturas
reales del árbol de widgets Flutter con datos simulados para validación.

## Validación

Suite Flutter completa: 11 pruebas. Se verificaron las cuatro pestañas,
búsqueda sin peticiones repetidas, reintento tras error, contenido vacío,
confirmación de canje, anchos 320/390/1024 y texto ampliado a 1.6.
La bienvenida también se prueba en 320/768/1440.

Análisis sin avisos en los archivos del rediseño. El análisis global mantiene
un aviso previo en `lib/core/network/api_client.dart`.
Compilación web correcta. No se ejecutó la app en Android o iOS físico;
insets del sistema y teclado nativo quedan pendientes de validación allí.

Para regenerar las capturas:

    flutter test test/mobile_design_test.dart --dart-define=BLOOMI_CAPTURE_DESIGN=true

Las fuentes e iconos incluyen sus licencias en assets/fonts y assets/icons.
