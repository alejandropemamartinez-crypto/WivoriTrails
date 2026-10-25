# Wivori Trails 0.23.1 · Golpes continuos y entrega por proximidad

El joystick sigue siendo el único control necesario para desplazarse, cortar,
cazar, recoger y entregar. No se pulsa ni se mantiene una acción de trabajo.

## Correcciones

- Un depósito vacío, un puesto sin carga o un botín que no cabe ya no bloquean
  el árbol u oso que también está al alcance. Se priorizan acciones disponibles.
- El alcance de las herramientas pasa de 2,5 a 3,2 metros sobre el terreno.
- La mochila ya no impide atacar cuando no cabe toda la recompensa. Se recoge
  lo que cabe y el resto queda en el suelo, con sus modelos y cantidades, hasta
  que el jugador o un recolector lo retira. Los centinelas conservan su botín.
  El botín tiene un límite de 48 unidades por recurso para evitar acumulación
  ilimitada; se indica cuándo es necesario recogerlo para seguir cosechando.
- Cada impacto reinicia la animación de la herramienta a su cadencia. El clip
  de un golpe ya no se queda detenido en la última pose durante golpes sucesivos.
- La entrega detecta el frente y los laterales o parte trasera del puesto según
  su superficie real. La misma zona sirve para atender pedidos antes de contratar
  cajeros. Un contorno verde señala el frente cuando llevás mercancía compatible.
- Entregar o recoger no espera a que termine el enfriamiento de un golpe anterior.
- El encabezado y el menú muestran 0.23.1 para identificar la instalación.

Se mantienen todos los oficios y sus requisitos de ventas y monedas de 0.23.0,
las vías, los seis destinos y el movimiento manual. El esquema comercial 3 añade
los troncos pendientes de recoger y conserva guardados 1 y 2, trabajadores,
inventarios y ambas campañas. El contenedor del guardado sigue siendo v8.

## Verificación

La nueva suite de regresiones reproduce los casos de depósito vacío, acceso a
ambas cajas desde cuatro lados, ataques al borde del alcance, mochila llena y
conservación de botín al guardar. Antes del arreglo fallaban 18 de sus 24 casos.

Una segunda prueba deja correr el bucle real de la escena y utiliza únicamente
eventos táctiles del joystick. No teletransporta al protagonista, no llama
directamente al proceso del juego y no pulsa trabajo. Recorre pinos, entrega
por un lateral, combate las tres variantes de oso, llena la mochila, conserva
el exceso de carne y entrega por detrás. Comprueba reinicios reales del clip
de animación y que alejarse o abrir un menú detiene las acciones del héroe.
Se ejecuta también con renderizado nativo en CI y produce capturas reales.

Las pruebas de escritorio y CI no sustituyen una comprobación en teléfono físico.
APK ARM64 0.23.1, código 28; mismo paquete y certificado para actualizar la partida.
