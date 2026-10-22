# Wivori Trails 0.20.0 · siguiente destino claro

El avance anterior exigía maximizar el mercado y después todos los talleres de
cada isla. La guía podía recomendar gastos ajenos al desbloqueo, no mostraba una
lista completa de requisitos y perdía el destino elegido al caminar al muelle.

## Cambios

- Tarjeta permanente con nombre del próximo pueblo, hitos completados, progreso
  y estado listo. Al tocarla, una lista muestra todos los requisitos y precios.
- Primer viaje: entregar 6 productos, contratar un ayudante (80), mejorar la caja
  una vez (140), vender 18 productos y preparar el barco (250). No exige nivel 6,
  cuatro ayudantes, defensas al máximo ni el muelle de exportación.
- El primer trigal de Villa Miga queda incluido con el barco. Sigue siendo una
  construcción manual en su terreno; una llegada sin monedas puede empezar.
- Las siguientes etapas requieren un operario del taller central y su primera
  mejora. Los demás operarios y niveles son expansión opcional. Se mantienen los
  proyectos y los seis contratos industriales, así como las tres expediciones.
- La guía conserva el destino seleccionado y ofrece EMBARCAR al llegar al muelle.
  El protagonista sigue moviéndose únicamente con joystick o teclado.
- La financiación inicial reúne lotes de seis productos; la venta sugerida en
  las islas reserva los materiales del proyecto pendiente.
- La descripción de la misión tiene espacio real para dos líneas. El destino,
  la misión y los avisos se distribuyen en filas separadas.
- Un encargo elegido conserva su guía. El tablero permite alternar entre la ruta
  de mapas y las misiones opcionales del mercado.
- El botón de pueblo abre directamente producción en las islas y se llama
  TALLERES en los destinos industriales.

## Compatibilidad y validación

Android ARM64, versión 0.20.0, código 23. Se conservan paquete, certificado de
prueba, identidad de almacenamiento y guardado v8. Los mapas ya abiertos no se
retiran; también se preservan inventario, caja y operarios comprados.

Las suites de Godot cubren progresión, viajes, economía, guardado y controles.
`journey_progress_tests.gd` recorre el primer viaje desde cero sin conceder dinero,
ventas ni mejoras. `two_island_economy_tests.gd` continúa con la economía real
de trigo, harina, pan y huevos hasta abrir Puerto Nata. `journey_ui_tests.gd` usa toques reales para abrir requisitos,
preparar y embarcar, y revisa la interfaz a 720×1280 y 720×1600. Las capturas de
este último usan estados preparados, no una partida humana completa.

CI importa recursos, arranca el juego, ejecuta regresiones, exporta el APK y
verifica versión, firma y ARM64. La evaluación de rendimiento y ritmo humano
en un teléfono físico permanece pendiente. No se presentan las simulaciones
como tiempo real de juego, ni como garantía de diversión o ausencia de bugs.
