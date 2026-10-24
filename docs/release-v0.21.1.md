# Wivori Trails 0.21.1 · movimiento disponible desde el inicio

La versión 0.21.0 escondía el movimiento en «Pasear». Además, centrar la vista,
viajar o reanudar Android volvía a desactivarlo. El control ahora está visible
desde el inicio y sigue disponible al volver de esas acciones.

## Correcciones

- Joystick visible, con instrucción directa, sin entrar a un menú para habilitarlo.
- Correr con otro dedo mientras se mantiene la dirección del primero.
- Cámara que sigue al personaje; arrastrar y pellizcar siguen funcionando.
- Ver pueblo y Centrar cambian la cámara sin desactivar los controles.
- Un pellizco no abre edificios por accidente ni salta al levantar uno de los dedos.
- Abrir un panel o pausar borra los dedos activos; cerrar no revive una orden vieja.
- Posición del personaje guardada por refugio y restaurada después de pausar.
- Controles con áreas separadas del objetivo y sin rótulos de edificios superpuestos.
- Fondo legible para el estado del tiempo al mover la cámara.
- Avisos de actividad con altura suficiente para mostrar el texto, en lugar de una barra vacía.
- El proyecto gratuito muestra «Kit incluido · Sin costo» también en la guía.

## Validación

Una nueva suite reproduce el fallo en 0.21.0: el primer gesto de movimiento no
desplazaba al personaje. La misma prueba ahora usa pulsación, arrastre y suelta,
sin escribir directamente el eje del joystick. Cubre ocho direcciones, velocidad
analógica, correr con otro dedo, cancelaciones, menús, cámara, escalado de
coordenadas, colisión, seis refugios y pausa/reanudación de Android.

Las comprobaciones se ejecutan sin gráficos y con el renderizador activo en
720×1280 y 720×1600. Son pruebas del motor con eventos de pantalla; no representan
una medición en un teléfono Android físico. Se conservan las suites anteriores.

Android ARM64 0.21.1, código 25. Se mantienen paquete, certificado de pruebas,
economía y ambos archivos de partida. Las partidas de 0.21.0 reciben una posición
inicial segura si todavía no tienen el nuevo campo opcional de posiciones.
