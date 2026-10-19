# Wivori Trails · campaña en desarrollo

Esta rama contiene los avances hasta la etapa 5N y el cierre de campaña de la
etapa 6: seis escenarios, mejoras locales para avanzar, diario voluntario,
tablero de pedidos rediseñado y expediciones desde Puerto Aurora.
[Diseño, alcance y comprobaciones pendientes](docs/CAMPANA-SECUENCIAL.md).

**Estado: código sin ejecutar en Godot ni compilar.** No se fusionó con `main`
ni se publicó un APK de estos cambios. La revisión estática no acredita calidad
visual ni ausencia de bugs. El protagonista sigue sin nombre. La etapa 7 ya
exportó el modelo y lo revisó en Blender; falta reimportarlo y comprobarlo
dentro de Godot y Android.

## Base publicada: 0.16.0

Protagonista sin nombre, nuevo rostro original, granjas con arquitectura propia,
agua animada y revisión de errores de viaje, carga y controles.
[Cambios y validación](docs/release-v0.16.md).

Juego 3D de aventura, comercio y construcción para Android, en Godot 4.4.1.
El jugador controla un perrito aventurero sin nombre: cara redondeada, pelaje
carbón, hocico corto, ojos ámbar y pañuelo mostaza. Los NPC conservan sus cinco
especies y modelos distintos. **Wivori Trails** sigue siendo el nombre del juego.

## Esta versión

- Modelo original `hero.glb`: malla ponderada, 17 huesos, 14 clips, atlas PBR de
  1024 px y fuente editable. Sustituye al antiguo personaje barbudo.
- Establo, gallinero y corral propios; cercas de madera abiertas con colisión.
- Sombras de contacto, luz equilibrada, caminos con relieve visual, agua con
  ondas y espuma de costa, vegetación ligera agrupada y molino animado.
- Operarios trabajan visualmente durante sus lotes. Movimiento del jugador
  siempre manual, con inclinación suave al girar y animaciones por actividad.
- Corregidos límites de islas, amarre del ferry, puerto visible en otra isla,
  altura del muelle, regeneración del trigo, carga visual y desbordes del almacén.
- El joystick ya no captura toques a través de menús o avisos abiertos.
- Se conservan doce capítulos del mercado, defensas, encargos, quince proyectos
  marítimos y los pueblos persistentes. Guardado v8 compatible con versiones v1–v8.

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
  del nivel una sola vez. Desde el nivel 7, **Pedidos** permite fabricar, recoger y entregar encargos.
  Después de doce capítulos alternan rutas de producción, rapidez y defensa.

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

## 0.15.0 — Ruta del Faro

El protagonista es exclusivo; los NPC tienen cinco siluetas distintas. Los oficios
separados, carteles opacos y avisos grandes enseñan la siguiente tarea.
Desde nivel 6, muelle y 900 monedas, el transbordador conecta tres pueblos nuevos.
Quince proyectos y doce construcciones conducen al Faro. Trigo, granjas de vacas,
gallinas y cerdos, ocho recetas y operarios por estación mantienen la producción
conectada entre destinos. El guardado v8 conserva el progreso anterior.

La comparación con Township, Hay Day y My Mini Mart y las decisiones están en
[docs/PROGRESION-v015.md](docs/PROGRESION-v015.md). Esta versión es un prototipo;
retención y rendimiento en teléfonos físicos todavía requieren pruebas.
