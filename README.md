# Wivori Trails · 0.4.0

Prototipo móvil 3D de recolección, comercio y automatización, en **Godot 4.4.1**.
Empezás cosechando y abasteciendo el puesto; contratás ayudantes y desbloqueás
un huerto de manzanas y un muelle que exporta el excedente automáticamente.

## Jugar y editar

Abrí `project.godot` en Godot 4.4.1 y ejecutá `Main.tscn`.
Los archivos editables del repositorio son la fuente vigente. El ZIP original
es histórico y no se extrae ni reemplaza los cambios al compilar.

- **Moverse:** joystick táctil, WASD/flechas o tocar el terreno. Las rutas rodean
  el puesto y los troncos; el joystick se desliza junto a los obstáculos.
- **Cosechar:** acercate a los cultivos con espacio en la mochila.
- **Vender:** pasá por el círculo dorado. Los compradores pagan al comprar.
- **Automatizar:** comprá ayudantes en Mejoras; recolectan y abastecen el puesto.
- **Exportar:** el muelle de 550 monedas carga lotes de 6 productos iguales
  cuando hay al menos 9, conserva 3 para el mercado y paga un 50 % extra al
  llegar, después de 30 segundos de juego. Incluye barco y seguimiento visible.

## Guardado

Guardado local automático cada 8 segundos, al comprar, al despachar/recibir
un barco y al pausar. Conserva monedas, mochila, stock, ayudantes con su carga,
posición y tarea, cultivos y envío en tránsito. Los archivos v1 se migran.
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
```

Las pruebas usan un guardado temporal propio y no modifican una partida normal.
Cubren recolección/venta, navegación, automatización, exportación, persistencia,
recuperación de respaldo, migración y datos malformados. El pipeline también
inicia la escena y comprueba el APK exportado.

**Estado:** versión de prueba. Falta validar gráficos, tacto, rendimiento y balance
en teléfonos reales. La movilidad del mercado y los diferentes destinos de la
idea original son trabajo futuro. Wivori Trails sigue siendo nombre provisional.
