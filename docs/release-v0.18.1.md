# Wivori Trails 0.18.1 — avisos legibles

Corrige el solape reportado en Android: MAPAS se dibujaba sobre la mensajera
que avisaba del robo, y el botón de defensa tapaba el mensaje inferior.

- Navegación y avisos tienen filas independientes. La fila de envíos queda
  después del aviso activo, sin atravesar la notificación de robo o de stock.
- El texto inferior se ajusta al ancho y queda completamente por encima del
  control más alto, incluyendo Ahuyentar y la tarjeta de mejora cercana.
- La mensajera usa todo el ancho disponible y conserva su animación lateral.
  Sus líneas cortas no solicitan una altura excesiva antes del primer layout.
- La instrucción Acercate al mapache tiene dos líneas, letra más grande y
  contraste oscuro aunque la acción todavía no esté disponible.
- Se respetan las áreas seguras del teléfono. Los avisos siguen sin bloquear
  el joystick; MAPAS continúa disponible durante el robo.

La regresión reprodujo 28 solapes antes de corregir el código. Se comprueban
720×1280, 720×1600 y dos áreas seguras simuladas con espacio superior de 64 e
inferior de 24. La prueba usa la escena real, notificaciones de robo, cola sin
stock y envíos simultáneos; incluye toques al botón MAPAS y capturas nativas.
El espacio seguro simulado no sustituye una nueva prueba en teléfono físico.

Android ARM64, versión 0.18.1, código 20. Conserva paquete, certificado de
prueba y guardado de 0.18.0; puede instalarse encima de ella.
