# Wivori Trails 0.23.0 · Acercate y automatizá

El personaje corta, golpea con la hoz, recoge y entrega automáticamente cuando
está cerca del objetivo. El jugador sigue dirigiendo cada desplazamiento con
joystick; contratar ayudantes nunca activa un piloto automático del héroe.
La antigua acción pulsada se reemplaza por un indicador con progreso. Alejarse,
abrir un menú o pausar impide que el protagonista siga golpeando fuera de alcance.

## Osos y herramientas

| Oso | Resistencia inicial | Carne |
| --- | ---: | ---: |
| Polar | 4 golpes | 6 |
| Blindado, con casco y placas de acero | 9 golpes | 9 |
| Acorazado, con protección reforzada | 16 golpes | 12 |

Las mejoras de herramientas aumentan el daño del héroe y sus cazadores y leñadores.
Los árboles dan cinco maderas. La mochila conserva su capacidad compartida y no
destruye un recurso cuando falta espacio para recoger su recompensa completa.

## Oficios que se desbloquean jugando

Los requisitos se verifican por pueblo; las monedas financian la contratación.
Taller muestra el avance del requisito, el costo y la cantidad de plazas ocupadas.
La guía señala una contratación disponible sin abrir un tutorial bloqueante.

| Contratación | Requisito | Monedas |
| --- | --- | ---: |
| Primer leñador | Vender 4 maderas | 60 |
| Segundo / tercer leñador | Vender 20 / 50 productos | 120 / 180 |
| Primer cazador | Vender 4 carnes | 120 |
| Segundo / tercer cazador | Vender 35 / 70 productos | 240 / 360 |
| Cajero de madera | Vender 4 maderas | 80 |
| Cajero de carne | Vender 4 carnes | 120 |
| Porteador | Vender 20 productos, ambos cajeros y algún recolector | 160 |
| Primer centinela | Vender 30 productos y contratar cazador | 220 |
| Segundo centinela | Vender 80 productos y contratar cazador | 360 |

Cada leñador y cazador es otro NPC con su propia ruta, objetivo y carga. Los
cajeros atienden sus respectivos puestos cuando el protagonista se aleja; sin
cajero, se atiende permaneciendo junto a la caja. Los puestos con personal atraen
más clientes para que la demanda acompañe al crecimiento del negocio.

El porteador carga hasta 12 productos del depósito y los distribuye caminando.
Los centinelas ocupan dos torres construidas y disparan proyectiles: la carne
queda en el terreno hasta que el jugador o sus cazadores la recogen. Ante un
robo, priorizan proteger el depósito y ahuyentan al mapache sin pulsar una alarma.
El ferrocarril sigue aportando transporte adicional con sus dos vagones.

## Ruta y partidas anteriores

La ruta muestra cinco metas: productos vendidos, primer leñador, primer cazador,
ambos cajeros y tres tramos de vías. En Paso Bruma se venden 40 productos y el
pasaje cuesta 80 monedas. Torre y porteador son mejoras adicionales, no requisitos
ocultos para viajar. Los mercados anteriores siguen trabajando con su personal.

Se conservan paquete Android, firma, guardado v8, refugios y archipiélago. El
guardado comercial añade sus campos con esquema 2: empleos independientes,
inventario del porteador, botín pendiente y proyectiles. Los puestos existentes
de v0.22 conservan su atención sin presencia reconociendo ambos cajeros, sin
volver a cobrarlos. No se regalan cajeros en destinos que antes estaban cerrados.

## Verificación

La suite de economía comprueba proximidad, resistencia y recompensas por variante,
requisitos y precios, independencia de trabajadores, atención presencial y por
cajeros, transporte, botín de torres, impactos diferidos, inventarios, migración,
datos corruptos y ganancias al volver. El recorrido de balance usa ventas y
contrataciones normales; su tiempo simulado omite desplazamientos y no mide
duración humana de juego.

La prueba táctil llega con el joystick a árboles, osos y puestos; no pulsa ninguna
acción de trabajo. Con esas ganancias compra cajeros, recolectores, porteador,
ambas torres y ferrocarril, verifica ingresos con el héroe lejos, defensa automática,
interfaces en ambas alturas, guardado y reanudación. La grabación usa frames
reales del motor y cortes entre actividades y el progreso ganado en esa prueba.
Las comprobaciones de escritorio y CI no miden el rendimiento en un teléfono físico.

APK ARM64 **0.23.0**, código **27**, paquete `sv.apenalegaltech.wivoritrails` y
misma firma de prueba para actualizar conservando la partida.
