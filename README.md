# Wivori Trails · 0.6.0

Prototipo móvil 3D de recolección, comercio y automatización, en **Godot 4.4.1**.
Empezás cosechando y abasteciendo el puesto; contratás ayudantes y desbloqueás
un huerto de manzanas y un muelle que exporta el excedente automáticamente.

## Novedades de 0.6.0

- Movimiento base de 6,8 unidades/s (antes 4,5), ayudantes de 4,2 (antes 2,8),
  cosecha más ágil y giros independientes de la tasa de cuadros. Correr suma 50 %.
- Flechas continuas sobre rutas transitables, un indicador en el borde para metas
  fuera de cámara y un marcador en el destino. Se ven sin tocar primero Guiar.
- Zonas de mejora en el mapa: equipo, mochila, velocidad, caja, huerto y muelle.
  Muestran precio y disponibilidad; acercarse abre la explicación y un botón de
  compra explícito. Pasar por una zona no gasta monedas.
- Al alcanzar el precio de la inversión recomendada, avisa una vez por escalón y
  cambia la guía a esa zona. La secuencia enseña cosechar, entregar, contratar,
  ampliar el equipo, mejorar la caja y abrir expansiones. Retoma partidas previas.
- Fila real con seis lugares y atención de a un cliente. Avisos de puesto vacío
  o fila saturada con un botón que guía a la solución. Caja rápida tiene tres
  mejoras: servicio de 4,6 → 2,6 → 1,55 → 0,95 segundos. Los compradores esperan
  sin penalización cuando falta mercadería.
- Caminos más limpios, paleta cálida, puesto con identidad Wivori, cultivos
  diferenciados, precios legibles, recibos de monedas y celebración al invertir.
  El HUD muestra nivel, progreso de ventas, fila y mejoras disponibles.
- Guardado v3: conserva caja, avisos ya vistos y las compras anteriores. Las
  partidas v1/v2 reciben la nueva velocidad base sin perder bonos comprados.

La investigación de diseño se basó en referencias primarias de Supersonic:
[guía de idle arcade](https://supersonic.com/learn/blog/how-to-ideate-and-build-a-profitable-idle-arcade-game/),
[caso Pro Builder](https://supersonic.com/learn/case-studies/pro-builder/) y la
[ficha oficial de My Mini Mart](https://play.google.com/store/apps/details?id=com.KisekiGames.smart).
Se aplicó el criterio de progresión visible, inversión que cambia el trabajo y
escenarios legibles. Las flechas, zonas, economía y personajes son implementación
propia; la investigación no demuestra retención ni rendimiento en este juego.

## Jugar y editar

Abrí `project.godot` en Godot 4.4.1 y ejecutá `Main.tscn`.
Los archivos editables del repositorio son la fuente vigente. El ZIP original
es histórico y no se extrae ni reemplaza los cambios al compilar.

- **Moverse:** joystick táctil, WASD/flechas o tocar el terreno. Las rutas rodean
  el puesto y los troncos; el joystick se desliza junto a los obstáculos.
- **Cosechar:** acercate a los cultivos con espacio en la mochila.
- **Vender:** pasá por el círculo dorado. Los compradores pagan al comprar.
- **Automatizar:** seguí las flechas hasta Equipo y confirmá la compra, o usá Mejoras. Los ayudantes recolectan y abastecen solos. Mejorá Caja si la fila crece.
- **Exportar:** el muelle de 550 monedas carga lotes de 6 productos iguales
  cuando hay al menos 9, conserva 3 para el mercado y paga un 50 % extra al
  llegar, después de 30 segundos de juego. Incluye barco y seguimiento visible.

## Guardado

Guardado local automático cada 8 segundos, al comprar, al despachar/recibir
un barco y al pausar. Conserva monedas, mochila, stock, ayudantes con su carga,
posición y tarea, cultivos, caja, avisos vistos y envío en tránsito. Los archivos v1/v2 se migran.
Escritura mediante archivo temporal y copia del último guardado válido para
recuperarse de una escritura interrumpida. Los viajes se reanudan al volver;
no hay simulación de ingresos con la aplicación cerrada.

## Android

GitHub Actions valida scripts, ejecuta las pruebas y genera un APK **ARM64 de
prueba** en cada cambio de `main`, pull request o ejecución manual. Descargalo
del artefacto `WivoriTrails_Android_debug` de una ejecución exitosa en Actions.
Verifica además el paquete, versión, integridad y certificado del APK generado.

La firma de desarrollo se mantiene entre compilaciones desde 0.4.0.
[Detalles de la llave pública de prueba y transición desde 0.3](tools/android/README.md).
El proyecto todavía no incluye anuncios ni compras integradas. La firma y el
formato de lanzamiento para Google Play se deben configurar por separado.

## Verificación local

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/gameplay_tests.gd
godot --headless --path . --script res://tests/mobile_ui_tests.gd
godot --headless --path . --script res://tests/progression_tests.gd
```

Las pruebas usan un guardado temporal propio y no modifican una partida normal.
Cubren recolección/venta, navegación, automatización, exportación, persistencia,
recuperación de respaldo, migración, datos malformados, guía espacial, compras
explícitas, alertas, cola serial y entrada táctil. La secuencia guiada llega al
primer ayudante en menos de 35 segundos simulados, usando ventas reales.
Son 27 comprobaciones de juego, 28 de progresión y 25 de interfaz sin renderizado;
con renderizado, la suite móvil añade dos comprobaciones geométricas del diseño.
El pipeline también inicia la escena y verifica el APK exportado.

Para capturas reales, ejecutar con un servidor gráfico y pasar una carpeta:

```sh
godot --path . --resolution 720x1280 --script res://tools/capture_preview.gd -- /tmp/wivori-preview
```

La revisión visual de 0.6.0 se realizó con OpenGL/Mesa en 720×1280 y 720×1600,
incluyendo inicio, inversión disponible, compra en el mapa, falta de stock, fila llena, mejoras y mercado ampliado. No sustituye las pruebas
de rendimiento y tacto en dispositivos Android físicos.

**Estado:** versión de prueba. Falta validar gráficos, tacto, rendimiento y balance
en teléfonos reales. La movilidad del mercado y los diferentes destinos de la
idea original son trabajo futuro. Wivori Trails sigue siendo nombre provisional.
