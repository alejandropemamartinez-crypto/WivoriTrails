# Wivori Trails · 0.23.1 · Mercado del Norte

Juego de recolección, comercio y automatización en la nieve para Android,
en Godot **4.4.1**. Cortá pinos con el hacha, cazá osos polares con la hoz y
llevá la carga a dos puestos con filas de clientes. Gastá las monedas en un
leñador, un cazador y tres tramos de ferrocarril que automatizan el transporte
y la venta. **El protagonista siempre se mueve bajo tu control.**

## Acercate → trabajá → contratá

Usá el joystick y mantené **Correr** con otro dedo si querés acelerar. Acercarte
a un pino activa el hacha; acercarte a un oso activa la hoz. Los golpes, la
recogida y la entrega en los puestos son automáticos. No hay botón de golpear.
El personaje nunca decide adónde caminar por vos.

La mochila llena no detiene los golpes: el botín que no cabe se conserva en el
suelo hasta que vos o tus ayudantes lo recogen. La entrega funciona al acercarte
al frente, los lados o la parte trasera del puesto. Un contorno verde señala la
zona frontal al llevar carga. Cada golpe vuelve a animar el hacha o la hoz.

[Correcciones y pruebas de 0.23.1](docs/release-v0.23.1.md).

Hay osos polares normales (4 golpes, 6 carnes), blindados (9, 9) y acorazados
(16, 12), con armadura original unida al cuerpo animado. Las herramientas
mejoradas reducen los golpes. La mochila empieza con 16 espacios compartidos.

**Taller** muestra qué ventas desbloquean cada oficio y su precio en monedas.
Podés contratar hasta tres leñadores, tres cazadores, dos cajeros, un porteador
y dos centinelas. Cada recolector tiene su ruta y su carga. Cada cajero atiende
un puesto aunque te alejés; sin cajero, atendés al permanecer junto a la caja.
El porteador reparte desde el depósito antes de que exista el tren. Los centinelas
disparan desde torres, dejan botín para recoger y repelen robos automáticamente.

Tres tramos de vías cierran el circuito de la locomotora: carga del depósito y
abastece madera y carne. La demanda de los clientes aumenta al ampliar el equipo.
**Ruta** muestra cinco metas y el precio del pasaje. El primer pueblo exige 40
productos vendidos, un leñador, un cazador, ambos cajeros, tres tramos y 80 monedas
para viajar. Las torres y el porteador son mejoras adicionales.

[Requisitos, precios, migración y verificación de 0.23.0](docs/release-v0.23.0.md).

## Refugios del Norte

La aplicación comienza en `Refuge.tscn`. Tocá edificios para construir, mejorar
y asignar trabajadores; arrastrá el terreno para desplazar la cámara y pellizcá
para acercarla. **Taller → Habitantes y edificios** muestra plazas y puestos de trabajo.
**Ruta** muestra las metas comerciales y la acción para viajar. El desarrollo del refugio sigue disponible como actividad adicional.

| Refugio | Nueva decisión |
| --- | --- |
| Paso Bruma | Calor, hogares y asignación de habitantes |
| Valle Ámbar | Enfermería e invernaderos con 25 % más de comida |
| Costa Cristal | Expediciones con 20 % menos tiempo de viaje |
| Cumbre Cobre | Cantera con 30 % más de producción de metal |
| Distrito Forja | Fundición con 35 % más de producción |
| Puerto Aurora | Tres expediciones distintas y producción de la red al 45 % |

- Diez clases de edificios, hasta ocho niveles, una obra a la vez y costos visibles.
- El primer aserradero está incluido: gastar mal al empezar no elimina la fuente de madera.
- Los habitantes trabajan solo cuando los asignás. **−** libera una persona para otro puesto.
- El carbón mantiene el calor; las noches y ventiscas exigen preparar el refugio.
- Las guardias reducen las señales necesarias para ahuyentar mapaches.
- Las expediciones reservan dos habitantes y entregan la recompensa una sola vez.
- Los otros refugios siguen produciendo al 35 %; Aurora mejora esa red al 45 %.
- Hasta dos horas de producción al volver, sin robos ni ventiscas fuera de pantalla.
- La guía indica el recurso concreto que falta y la cuenta regresiva de las obras.
- El joystick está visible desde el inicio. **Correr** funciona al mantener otro dedo.
- **Ver pueblo** abre la vista general; **Centrar** vuelve al protagonista. Ambas permiten seguir caminando.
- Viajar, cerrar un menú o volver a la app conserva el movimiento manual y la posición del personaje.
- Ninguna misión mueve al protagonista automáticamente.

La partida anterior sigue en **··· → Continuar mi archipiélago**. Desde su
**Mapa y meta** podés volver al refugio. Usa su archivo original de guardado v8;
el refugio guarda en un archivo separado y no convierte ni descuenta ese progreso.

## Archipiélago anterior

Mercado de Wivori → campos de Villa Miga → granjas de Puerto Nata →
Bahía Farol → Distrito Forja → astillero de Puerto Aurora.

Hay 24 proyectos marítimos, 11 recetas, mejoras locales, seis contratos mixtos
de industria y tres rutas de expedición. Para pasar al siguiente escenario hay
que completar una lista visible de hitos. El primer viaje requiere entregar
6 productos, contratar un ayudante, mejorar la caja una vez, vender 18 productos
y preparar el barco por 250 monedas. El primer trigal está incluido. Más
empleados y niveles avanzados de mejora son opcionales. Las partidas antiguas conservan
sus destinos, inventario y edificios. [Diseño de la campaña](docs/CAMPANA-SECUENCIAL.md).

- Joystick o WASD/flechas para caminar; mantener **Correr** para acelerar.
- Acercarse a cultivos cosecha. Llevar la mochila a **Entregar** repone el puesto.
- Las ventas dejan monedas en cajas físicas: acercate para cobrarlas.
- **Mejoras** muestra trabajadores, herramientas y defensas. Las flechas guían;
  el protagonista siempre se mueve bajo tu control.
- Desde nivel 3 podés acercarte a un mapache y **Ahuyentarlo**.
- **Pueblo** permite construir y mover edificios entre solares.
- **Continuar** cobra el premio del nivel una sola vez.
- La tarjeta del **próximo mapa** muestra su nombre, los hitos completados y
  cuándo está listo. Al tocarla ves cada requisito y el botón para señalarlo.
- Elegir un destino abierto lo conserva hasta el muelle; allí tocás **Embarcar**.
- **Mapas** muestra destinos, metas y mejoras pendientes; **Granja y carga**
  permite gestionar recetas y operarios. En Aurora, **Flota** prepara expediciones.
- Las novedades se abren voluntariamente desde el mapa. Las colas, cosechas y
  tareas repetidas no abren tarjetas que congelen la partida.

## Ejecutar y verificar

Abrí `project.godot` con Godot 4.4.1 y ejecutá el proyecto. La escena de inicio
es `Refuge.tscn`; `Main.tscn` conserva el archipiélago anterior.

```sh
godot --headless --path . --import
for suite in tests/*_tests.gd; do
  timeout 120 godot --headless --path . --script "res://$suite"
done
```

Para las comprobaciones con gráficos activos:

```sh
godot --path . --resolution 720x1600 --audio-driver Dummy \
  --script res://tests/refuge_trade_touch_tests.gd -- /tmp/mercado-capturas
godot --path . --resolution 720x1600 --audio-driver Dummy \
  --script res://tests/refuge_movement_tests.gd
godot --path . --resolution 720x1600 --audio-driver Dummy \
  --script res://tests/refuge_ui_tests.gd
godot --path . --resolution 720x1280 --audio-driver Dummy \
  --script res://tools/capture_refuge.gd -- /tmp/refugio-capturas
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
verifica paquete, versión y certificado. 0.23.1 usa código 28, el paquete
`sv.apenalegaltech.wivoritrails` y la misma firma de prueba de 0.16.0 para
actualizar conservando el guardado v8. [Firma de prueba](tools/android/README.md).

[Licencias y fuentes editables](art/ASSETS.md). Los GLB están en `assets/models/`;
los generadores, atlas y archivos Blender en `art/source/`. Blender no es
necesario para ejecutar o compilar el juego.

[Corrección de movimiento en 0.21.1](docs/release-v0.21.1.md).

La arquitectura nevada, los iconos y los materiales están en `scripts/refuge_*`.
Son fuentes propias; no se incluyen imágenes, personajes ni interfaces de
Whiteout Survival. [Referencia de diseño y alcance](docs/REFUGIOS-DEL-NORTE.md).

[Renovación visual de 0.19.1](docs/release-v0.19.1.md): arquitectura costera,
materiales pintados, cámara ortográfica, tejados que dejan ver al protagonista,
catálogo con imágenes de los modelos actuales y avisos de robo sin duplicados.
Las pruebas de escritorio y de exportación no miden FPS, calentamiento, batería
ni sensación de control en un teléfono físico. El arte y el balance siguen
siendo los de una versión de prueba; la comparación de diseño con otros juegos
está en [PROGRESION-v015.md](docs/PROGRESION-v015.md).
