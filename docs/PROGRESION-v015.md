# Wivori Trails: ruta de los tres pueblos

Objetivo: reconstruir el Faro de la Ruta y conectar Wivori, Villa Miga,
Puerto Nata y Bahía Farol mediante un transbordador controlado por el jugador.
Scottie conserva el movimiento manual. Los empleados automatizan tareas concretas.

## Referencias y decisiones

| Juego / fuente del desarrollador | Bucle observado | Aplicación propia |
|---|---|---|
| Township, Port and ships: https://playrix.helpshift.com/hc/en/3-township/faq/15036-port-and-ships/ | Restaurar puerto, abrir islas y traer bienes diferentes | Barco que lleva al personaje a pueblos construibles, con progreso persistente y regreso libre |
| Hay Day, https://supercell.com/en/games/hayday/ | Cultivar, cuidar animales, transformar y vender | Trigo → harina → pan; alimento → leche → queso; ingredientes de distintos pueblos para provisiones |
| My Mini Mart, ficha del desarrollador: https://apps.apple.com/in/app/my-mini-mart/id1592004814 | Recolección activa, procesamiento y contratación de empleados | Mantener el joystick y contratar producción por estación; no automatizar al protagonista |

Estas decisiones son hipótesis de diseño, no pruebas de retención ni garantía de horas.
No se copian personajes, mapas, nombres de productos distintivos ni recursos artísticos.

## Cambios de presentación

- Scottie es el único terrier. Zorros, cerditos, patos, conejos y mapaches tienen siluetas propias.
- Oficios separados en avenidas; posiciones compartidas por arte, compra y navegación.
- Carteles opacos con borde de color, tinta oscura y pictogramas; sin texto blanco sobre el suelo.
- Presentación de etapa y misión terminada en una tarjeta que ocupa al menos tres cuartos de la pantalla. Confirmar detiene y limpia el joystick.
- Mostrar la siguiente inversión y el destino; las flechas nunca mueven al jugador.

## Progresión

El mercado original y sus doce capítulos se conservan. La ruta marítima se presenta
en nivel 6 y requiere construir el muelle y restaurar el transbordador.
Cada pueblo nuevo tiene proyectos secuenciales de construcción, producción,
entregas y mejoras. El siguiente destino depende de terminar los proyectos
anteriores. No se reinicia el mercado ni se borran construcciones al viajar.
Los productos de pueblos anteriores se necesitan en las últimas etapas.

La campaña termina con el faro reconstruido; después quedan contratos de comercio
y mejoras de producción opcionales, con una indicación clara de campaña completada.
No se disfraza la repetición como contenido nuevo ni se exige esperar horas reales.

## Verificación exigida

Migración del guardado anterior; recursos y gastos exactamente una vez;
viaje de ida, regreso y recarga; límites de producción y capacidad;
entrada libre a edificios; alertas legibles en 720×1280 y 720×1600;
Scottie exclusivamente protagonista. Capturas del motor, APK firmado con la clave existente.
