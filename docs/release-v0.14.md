Wivori Trails 0.14.1 — versión de prueba para Android ARM64.

- Scottie conserva su nombre. Hocico más proporcionado, barba integrada y pelaje
  gris con variación irregular suave en lugar de franjas que parecían madera.
- Cabecera e instrucciones compactas, avisos breves y carteles que se retiran en
  los robos para dejar visible la acción. Catálogo enfocado en el edificio pedido.
- Caminos curvos entre solares, bancos, carros de flores y cuatro vecinos móviles.
- Cultivos y decoración repetida comparten MultiMesh; MSAA 2x reduce coste gráfico.
- Doce capítulos definidos. Luego alternan rutas de producción, rapidez y defensa;
  no se presentan como capítulos infinitos con contenido único.
- Tres recetas: compota, merienda y cesta. Elegís qué fabricar, reservás ingredientes
  de mochila y puesto, recogés el lote terminado y lo llevás personalmente al despacho.
- Encargos sin apuro o con 100 segundos para ganar 90 extra. Llegar tarde conserva
  el encargo y su pago base. Dos mejoras de talleres reducen el tiempo de los lotes.
- Rondas de defensa que iniciás vos: detener dos mapaches, uno personalmente,
  sin perder mercancía. Se pueden repetir.
- Partidas v1–v6 compatibles; v7 guarda fabricación, lotes en transporte y rondas.
- Recompensas comerciales a las cajas físicas; no se añade movimiento automático.

Pruebas: importación y arranque de Godot 4.4.1; regresiones de economía, controles,
persistencia, construcción y defensa; escenarios de pedidos interrumpidos y pagos
sin duplicación; eventos táctiles reales en la interfaz nativa; capturas del motor.
Android se exporta y verifica en GitHub Actions, con la identidad y firma anteriores.

Las mediciones de Linux/Mesa corresponden al host. No se dispuso de teléfono o
emulador Android compatible: FPS, calentamiento, batería y manejo físico Android
siguen pendientes. Las capturas representan estados preparados para revisión.

Los .blend son editables, con sus licencias en art/. Para reexportar el terrier
esculpido y los accesorios se utiliza art/source/export_authored.py. El generador
anterior build_assets.py se conserva para el resto del arte y la historia del proyecto.
Esta entrega continúa siendo una versión de prueba, sin afirmar equivalencia de
acabado comercial con Township.

Corrección final de visibilidad: el despacho queda junto al camino principal,
con el jugador y la mercancía a la vista durante la entrega.
