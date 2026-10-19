# Wivori Trails · 0.18.0

Juego 3D de aventura, comercio y construcción para Android, en Godot **4.4.1**.
Controlás un perrito sin nombre; contratás trabajadores, defendés el mercado y
conectás seis pueblos con producción y objetivos propios.

## Campaña

Mercado de Wivori → campos de Villa Miga → granjas de Puerto Nata →
Bahía Farol → Distrito Forja → astillero de Puerto Aurora.

Hay 24 proyectos marítimos, 11 recetas, mejoras locales, seis contratos mixtos
de industria y tres rutas de expedición. Para pasar al siguiente escenario hay
que desarrollar las instalaciones del anterior. Las partidas antiguas conservan
sus destinos, inventario y edificios. [Diseño de la campaña](docs/CAMPANA-SECUENCIAL.md).

- Joystick o WASD/flechas para caminar; mantener **Correr** para acelerar.
- Acercarse a cultivos cosecha. Llevar la mochila a **Entregar** repone el puesto.
- Las ventas dejan monedas en cajas físicas: acercate para cobrarlas.
- **Mejoras** muestra trabajadores, herramientas y defensas. Las flechas guían;
  el protagonista siempre se mueve bajo tu control.
- Desde nivel 3 podés acercarte a un mapache y **Ahuyentarlo**.
- **Pueblo** permite construir y mover edificios entre solares.
- **Continuar** cobra el premio del nivel una sola vez.
- **Mapas** muestra destinos, metas y mejoras pendientes; **Granja y carga**
  permite gestionar recetas y operarios. En Aurora, **Flota** prepara expediciones.
- Las novedades se abren voluntariamente desde el mapa. Las colas, cosechas y
  tareas repetidas no abren tarjetas que congelen la partida.

## Ejecutar y verificar

Abrí `project.godot` con Godot 4.4.1 y ejecutá `Main.tscn`.

```sh
godot --headless --path . --import
for suite in tests/*_tests.gd; do
  timeout 120 godot --headless --path . --script "res://$suite"
done
```

Para las comprobaciones con gráficos activos:

```sh
godot --path . --resolution 720x1280 --audio-driver Dummy \
  --script res://tests/mobile_ui_tests.gd
godot --path . --resolution 720x1280 --audio-driver Dummy \
  --script res://tests/campaign_touch_tests.gd
godot --path . --resolution 720x1600 --audio-driver Dummy \
  --script res://tools/capture_campaign.gd -- /tmp/wivori-capturas
```

Las capturas del motor usan estados preparados para inspección: seis mapas,
tablero de pedidos, flota, héroe frontal/lateral/posterior y seis poses animadas.
No representan una partida humana completa. CI ejecuta las suites, pruebas
nativas de interfaz y capturas en 720×1280 y 720×1600.

## Android y arte

El flujo Android importa, arranca el juego, ejecuta las pruebas, exporta ARM64 y
verifica paquete, versión y certificado. 0.18.0 usa código 19, el paquete
`sv.apenalegaltech.wivoritrails` y la misma firma de prueba de 0.16.0 para
actualizar conservando el guardado v8. [Firma de prueba](tools/android/README.md).

[Licencias y fuentes editables](art/ASSETS.md). Los GLB están en `assets/models/`;
los generadores, atlas y archivos Blender en `art/source/`. Blender no es
necesario para ejecutar o compilar el juego.

[Correcciones y validación de 0.18.0](docs/release-v0.18.md).
Las pruebas de escritorio y de exportación no miden FPS, calentamiento, batería
ni sensación de control en un teléfono físico. El arte y el balance siguen
siendo los de una versión de prueba; la comparación de diseño con otros juegos
está en [PROGRESION-v015.md](docs/PROGRESION-v015.md).
