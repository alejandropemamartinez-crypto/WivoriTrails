# Wivori Trails · 0.12.0 — Recaudación tangible y movimiento controlado

- Las ventas **no llegan automáticamente a tu bolsillo**. Cada venta alimenta pilas de monedas visibles en una caja física. Scottie debe pasar a un radio de dos metros para recoger toda la pila, con monedas y cifras animadas.
- La primera mejora de **Caja rápida** abre una segunda caja recaudadora, con saldo propio. Las ventas se distribuyen entre ambas.
- Podés contratar una sola vez al **conejo recaudador** por 620 monedas. El ayudante camina hasta la caja con más saldo, recoge el dinero, vuelve a tesorería y solo allí acredita las monedas a tu cartera. Se guarda incluso el efectivo que lleva consigo durante el trayecto.
- El HUD diferencia las **monedas disponibles** del saldo **EN CAJAS**; no permite comprar mejoras con dinero todavía no recogido.
- Turbo ahora conserva la respuesta proporcional del joystick pero limita la velocidad máxima a 9.2 (10.6 con sprint). Mejora suave y parada inmediata al soltar.
- Se mantienen construcciones y niveles. Las partidas anteriores inician con caja recaudadora vacía y conservan el dinero de bolsillo.
- Este es un avance de jugabilidad y animación de recompensas. No sustituye todavía modelos orgánicos profesionales ni el acabado visual de Township.

## Versión previa

# Wivori Trails · 0.11.0 — Scottish Terrier & Animated Alerts

**Objetivo de esta etapa:** dirección de arte original, no un clon de Township.

- El personaje controlable es ahora un **terrier escocés gris atigrado** con silueta de orejas erguidas, hocico largo con barba esculpida y cejas claras. La cara está pintada sobre una malla continua.
- Cada mejora dispone de un cartel elevado, **delante y por encima** del techo; placa cálida contrastada con título grande, precio y símbolo tridimensional propio.
- El conejo mensajero aparece con ojos asustados y animación elástica cuando se aproximan mapaches o se llevan productos. Su ilustración SVG es original y escalable.
- Botones con profundidad, sombras, bordes inferiores y tipografía más gruesa. Se mantiene el manejo táctil simultáneo con joystick.
- El juego conserva progresión, construcción de nueve edificios, ventas, cosecha y defensa. Los datos de guardado existentes no se reinician.
- **Limitación artística:** todavía es un juego de personajes procedurales, no cuenta con modelos orgánicos con rigging ni clips de animación profesionales. El SVG animado es un retrato 2D dentro del HUD.
- **Validación:** pruebas GitHub Actions para compilación Android y capturas de la escena real, incluidos el terrier en primer plano y la alerta.

## Historial anterior

# Wivori Trails · 0.9.0 — primer pueblo construible

Juego móvil 3D de comercio, automatización y defensa en **Godot 4.4.1**.
Vos controlás al protagonista. Los empleados cosechan y reponen mientras vos
cumplís metas, entregás pedidos premium y protegés el puesto de mapaches ladrones.

## El pueblo comienza a crecer en 0.9.0
- Modo **PUEBLO**: cambia del joystick a una cámara elevada; tocás uno de tres solares y construís sin teletransportar al personaje.
- Tres edificios con repercusiones REALES: Casa de vecinos (clientes llegan 25 % más rápido), Café (+20 % por venta), Almacén comunal (+6 unidades de mochila).
- Los edificios se levantan con animación sobre los solares, tienen colores propios y permanecen al cerrar la aplicación.
- Animaciones de cosecha con indicadores +1, productos que salen de la mochila al entregar y cifras de monedas que vuelan a la caja.
- Robos visuales: los mapaches llevan una caja visible al robar, los artículos vuelan desde el almacén y regresan al recuperarlos. Desde el nivel 4 aparecen grupos de ladrones crecientes.
- HUD simplificado para aventuras y panel dedicado de construcción; el modo PUEBLO oculta los controles de caminar.
- Las compras requieren acción explícita y las partidas v1–v4 siguen cargando. Godot y Android se validan en GitHub Actions.
- **No es Township ni pretende copiarlo**. Las referencias son progresión visual y construcción en paralelo al juego de aventura.

## Cambios de arte en 0.8.0
- El protagonista es ahora un perrito aventurero con ropa turquesa y sombrero terracota; el vendedor conserva su identidad canina.
- Cabeza orgánica: malla continua reutilizable de polígonos suavizados, hocico integrado y rasgos faciales pintados mediante shader. Elimina la cabeza-esfera como modelo principal; ojos y nariz no son piezas 3D separadas.
- Iluminación fílmica con exposición limitada, color ambiental menos blanco y senderos de piedra en tonos arena.
- Conserva el control manual, capítulos, defensas y todas las mecánicas de 0.7.0. La nueva dirección de arte aún necesita artistas 3D para alcanzar el estilo de las ilustraciones originales.
- Nuevo control automatizado comprueba especie protagonista, malla de cabeza, material facial y tonemapping.

## Cambios de 0.7.0

- Protagonista con control manual exclusivo mediante joystick/WASD/flechas.
  Señalar, tocar el terreno o una alerta solo marca el destino: no camina solo.
- Personajes reconstruidos con proporciones compactas y cara pintada sobre la
  superficie de la cabeza. No hay ojos, narices ni dientes separados en el aire.
  Incluyen parpadeo, respiración, pasos según distancia, postura de carga y
  acciones de cosecha, entrega y ahuyentamiento. Apoyan los pies en el terreno.
- Seis niveles iniciales con objetivos, desbloqueos y recompensa explícita.
  Después continúan contratos que rotan de producto y aumentan su cantidad.
  Las entregas de empleados no cuentan como trabajo manual del protagonista.
- A partir del tercer nivel llegan incursiones con aviso previo. Los ladrones
  abren el almacén, toman hasta 8 productos reales e intentan escapar. Podés
  recuperar su carga acercándote y tocando Ahuyentar; no hay ataques violentos.
- Tres defensas con tres mejoras cada una: el almacén seguro demora el robo;
  la alarma extiende el aviso y ralentiza al ladrón cerca del puesto; el guardia
  patrulla e intercepta, con descanso entre intervenciones. Su recuperación se
  guarda. Varias entradas y ladrones simultáneos requieren atención del jugador.
- Desde el nivel 4 hay un carro de pedidos premium. Debés llevar personalmente
  el producto solicitado: paga ×2 y solo acepta la cantidad pendiente. Es una
  actividad adicional a la reposición normal que ya realizan los ayudantes.
- Guardado v4 con niveles, metas manuales, pedidos, defensas y ladrones con su
  carga. Cerrar la app no duplica ni elimina la mercadería robada. Migra v1–v3
  conservando compras, inventario y bonificaciones de velocidad anteriores.

## Niveles

| Nivel | Meta principal | Nueva decisión |
| --- | --- | --- |
| 1 · Primer puesto | Vender 12, entregar 6 personalmente y contratar un ayudante | Cuándo automatizar |
| 2 · Hora punta | Vender 18 adicionales, entregar 12 y tener dos ayudantes | Producción y atención |
| 3 · Manos largas | Vender 24, entregar 12, instalar cerrojo y frenar un ladrón | Invertir en defensa o interceptar |
| 4 · Pedidos de manzana | Entregar 8 manzanas premium, abrir huerto y frenar un ladrón | Desviar tiempo a un pedido ×2 |
| 5 · Comercio en ruta | Entregar 12 arándanos premium, exportar un lote y frenar dos ladrones | Exportación, pedidos y seguridad |
| 6 · Mercado protegido | Entregar 16 zanahorias premium, tener alarma/guardia y frenar dos ladrones | Coordinar defensas con descansos |
| 7 en adelante | Contratos rotativos, hasta 30 unidades, exportaciones alternas e incursiones de hasta tres ladrones | Equilibrar ingresos y protección |

Al cumplir todas las metas y resolver la incursión activa, tocá **Continuar**.
El premio comienza en 80 monedas y aumenta 40 por nivel, hasta 800. Conservás
el mercado y sus mejoras. Se reemplazó el antiguo premio genérico cada 20 ventas.
Los clientes siguen usando una fila de seis lugares y una caja mejorable.

## Jugar y editar

Abrí `project.godot` y ejecutá `Main.tscn`. Los archivos del repositorio son la
fuente vigente; el ZIP original es histórico y no se extrae al compilar.

- **Moverse:** joystick, WASD o flechas. Mantener Correr aumenta 50 % la velocidad.
- **Cosechar:** acercarse a un cultivo con espacio en la mochila.
- **Abastecer:** llevar productos al círculo dorado; la transferencia es automática.
- **Invertir:** acercarse a una zona y confirmar, o usar Mejoras. Pasar no compra.
- **Pedido premium:** desde el nivel 4, llevar el producto indicado al carro ×2.
- **Defender:** acercarse al mapache y tocar Ahuyentar. Tiene 2 s de recuperación.
- **Exportar:** muelle de 550 monedas; envía 6 productos iguales si hay 9, conserva
  3 para el puesto y paga 50 % adicional después de 30 segundos de juego.

La velocidad base es 6,8 unidades/s y la de los ayudantes 4,2. Las rutas de los
NPC y las flechas comparten el mapa de obstáculos. El jugador no usa autopiloto.
No se simulan ingresos ni incursiones con la aplicación cerrada. Las incursiones
se detienen al abrir Mejoras para permitir revisar e invertir.

## Android y guardado

GitHub Actions importa, inicia, prueba y exporta un APK ARM64 de prueba; verifica
paquete, versión, integridad y certificado. La identidad de firma se mantiene
desde 0.4.0, compatible con actualizaciones sobre 0.5/0.6.
[Detalles de la llave pública de desarrollo](tools/android/README.md).
El proyecto no incluye anuncios ni compras integradas. La publicación en Google
Play necesita una configuración de lanzamiento y firma propia.

Guardado automático cada 8 s, al comprar, al pausar y en cambios de incursiones,
envíos, pedidos y niveles. Escritura temporal más copia del último archivo válido.
Las partidas anteriores empiezan en el capítulo que corresponde a sus compras;
las antiguas entregas automáticas no completan los nuevos objetivos manuales.

## Verificación

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/gameplay_tests.gd
godot --headless --path . --script res://tests/mobile_ui_tests.gd
godot --headless --path . --script res://tests/progression_tests.gd
```

Las suites usan archivos temporales propios. Cubren economía, navegación NPC,
control manual, entrada táctil, progresión, compras, guardias, robo/recuperación,
escape, pedidos ×2, premios, migración y guardado de carga sin duplicación.

```sh
godot --path . --resolution 720x1280 --script res://tools/capture_preview.gd -- /tmp/wivori-preview
```

Se revisan capturas reales de OpenGL/Mesa a 720×1280 y 720×1600: inicio, modelos
de frente, intercepción, recuperación, carro premium y defensas. La suite móvil
con renderizado comprueba también límites y separación de controles en capítulos
posteriores. Estas verificaciones no sustituyen jugar ni medir el rendimiento
en un Android físico. La estética sigue siendo procedural; no se presenta como
arte comercial terminado ni como balance validado con jugadores.
