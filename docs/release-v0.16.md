# Wivori Trails 0.16.0 — Nuevo protagonista y revisión visual

El protagonista ya no tiene nombre en el juego. Su modelo original nuevo tiene
cara redondeada, hocico corto, ojos ámbar integrados y pañuelo mostaza. Incluye
17 huesos, 14 clips de animación y atlas PBR de 1024 px. Los NPC son distintos.

Establo, gallinero y corral con fachadas propias; cercas abiertas, sombras de
contacto, iluminación equilibrada, caminos nuevos, agua animada y espuma de
costa. El molino gira y los operarios se animan durante su trabajo. El héroe
sigue siendo controlado manualmente.

## Errores corregidos

- Caminar sobre el agua en esquinas de las islas.
- Ferry desplazado tras viajes y puerto de Wivori visible en otras islas.
- Pies hundidos en el embarcadero por prioridad incorrecta de altura.
- Trigo que regeneraba inmediatamente al visitar otro pueblo.
- Animación de carga después de vaciar la mochila.
- Pérdida de productos al depositar sobre el límite del almacén.
- Joystick que interceptaba toques a través de menús abiertos.

Conserva las partidas v1–v8, el paquete Android y el certificado de las versiones
anteriores. Puede instalarse encima de 0.15.0 sin borrar el progreso.
Fuentes editables y licencias en Wivori_Trails_Art_Source_v0.16.0.zip.

## Validación

Pruebas de producción, viajes, los quince proyectos, guardado y controles;
capturas nativas del motor en dos proporciones verticales. Siete fallos de
regresión se reprodujeron antes de aplicar las correcciones. Los detalles de
la nueva revisión están en tests/polish_tests.gd.

Es una versión de prueba. No se midió FPS en un teléfono Android físico ni se
puede garantizar ausencia total de errores o calidad visual comercial.
