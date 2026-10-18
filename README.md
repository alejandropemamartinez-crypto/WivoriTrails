# Wivori Trails · 0.14.0

Talleres con encargos y entregas manuales, doce capítulos, rondas de defensa,
Scottie refinado e interfaz compacta. [Cambios y validación](docs/release-v0.14.md).

Juego 3D de aventura, comercio y construcción para Android, en Godot 4.4.1.
Esta versión continúa íntegramente la rama de recaudación 0.12 (PR #9).
El protagonista es un Scottish Terrier gris atigrado. Se conserva el nombre
**Wivori Trails**.

## Cambios de esta versión

- Tres personajes originales modelados en Blender: terrier, conejo y mapache.
  Mallas orgánicas con piel ponderada, 17 huesos y 14 clips por personaje.
  Barba, cejas y hocico del terrier integrados en la superficie de la cabeza.
- Materiales PBR y atlas originales; tejados curvos con tejas individuales,
  puertas y ventanas arqueadas, molduras, toldos, maceteros y utilería de oficio.
  Nueve edificios económicos, diez puestos de mejoras y mercado reconstruidos.
- Interfaz con Quicksand (SIL OFL), iconos propios, catálogo de edificios con
  miniaturas renderizadas de los modelos y apartados Contratar / Mejorar.
- Mensajera 3D animada: alerta, dirección del ataque y reacción de alivio.
  El aviso no bloquea el joystick ni el botón de defensa.
- Ventas → cajas físicas → monedas en tránsito → cartera. El dinero es
  gastable únicamente al terminar su recorrido. La primera mejora de caja abre
  la segunda. El conejo recoge, carga una bolsa visible y deposita en tesorería.
- Guardado v6: conserva las partidas v1–v5, incluidas ventas pendientes,
  dinero transportado, mejoras, cultivos, empleados, construcciones e incursiones.
- Movimiento analógico, aceleración y frenado suaves, giro y cámara con seguimiento.
  La guía marca el destino; el protagonista siempre se mueve con tus controles.
- Barrios y construcciones por nivel; traslado de edificios a solares abiertos
  sin volver a cobrarlos ni duplicar bonificaciones. Colisiones y rutas se
  actualizan también al moverlos. Se mantienen los nueve efectos económicos.
- Frutas reconocibles al cosechar, entregar, comprar y recuperar. Los mapaches
  llevan el producto que realmente robaron. Más espacio entre incursiones.

## Jugar

Abrí `project.godot` con Godot **4.4.1** y ejecutá `Main.tscn`.

- Joystick o WASD/flechas para caminar; mantener **Correr** para acelerar.
- Acercarse a los cultivos cosecha; llevar la mochila a **Entregar** repone stock.
- Las monedas de las ventas quedan en las **cajas**: acercate a recogerlas.
- **Mejoras** permite contratar empleados y comprar herramientas o defensas.
- **Pueblo** eleva la cámara. Arrastrá para explorar y tocá un solar para construir.
  Seleccioná un edificio y **Mover edificio** para elegir un solar de destino.
- Desde el nivel 3, protegé los productos: acercate al mapache y tocá **Ahuyentar**.
- Desde el nivel 4 hay pedidos premium ×2; el muelle exporta excedentes.
- Las metas requieren entregas tuyas, pedidos y defensa. Los empleados no
  completan automáticamente el trabajo personal. **Continuar** cobra el premio
  del nivel una sola vez. Después de seis capítulos siguen contratos rotativos.

## Arte editable y procedencia

[Inventario, licencias y reproducción del arte](art/ASSETS.md).
Los `.blend`, atlas y generador están en `art/source/`. Los GLB de ejecución
están en `assets/models/`. No hace falta instalar Blender para jugar o compilar.
El ZIP histórico `wivori_bundle.zip` no se extrae ni se incluye en el APK.

## Comprobación

```sh
godot --headless --path . --import
for suite in tests/*_tests.gd; do
  timeout 120 godot --headless --path . --script "res://$suite"
done
```

Las suites comprueban economía, entrada táctil simultánea, rutas, niveles,
compras, robos/recuperación, guardias, pedidos, exportaciones, migración,
recaudador, dinero en tránsito, traslado de edificios y animaciones esqueléticas.

```sh
godot --path . --resolution 720x1280 --audio-driver Dummy \
  --script res://tools/capture_preview.gd -- /tmp/wivori-capturas
```

Las capturas se producen con el motor real y una partida de prueba preparada;
no son ilustraciones ni maquetas. Se revisan también a 720×1600.
`tools/render_thumbnails.gd` regenera las miniaturas a partir de los modelos.

## Android

GitHub Actions importa recursos, inicia el juego, ejecuta las suites, exporta y
verifica el APK ARM64, el paquete `sv.apenalegaltech.wivoritrails`, su versión y
el certificado de desarrollo estable. No se cambia la identidad de firma de
las versiones anteriores. [Detalles de firma](tools/android/README.md).

Es una versión de prueba. La revisión de escritorio y las comprobaciones
programáticas no sustituyen las pruebas de manejo, temperatura, memoria y FPS
en un teléfono Android. El acabado y el balance necesitan validación con
jugadores; no se presenta como un juego comercial terminado ni como equivalente
a una producción de Playrix. Todos los recursos nuevos tienen identidad propia.
