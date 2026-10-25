# Wivori Trails 0.22.0 · Mercado del Norte

La campaña nevada ahora incluye el circuito manual de recolección, venta y
automatización. El personaje se mueve únicamente con joystick, teclado o flechas;
las compras contratan NPC, nunca activan un piloto automático del protagonista.

- **Hacha y pinos:** acercate y mantené el botón de acción. Tres golpes llenan
  la mochila con cinco unidades de madera. El árbol cae y vuelve a crecer.
- **Hoz y osos polares:** cuatro golpes dan seis paquetes de carne, sin sangre.
  Los osos tienen cuerpo, patas, cabeza y cara animados; sus zonas se repueblan.
- **Dos puestos y filas reales:** cada cliente pide de dos a cuatro unidades.
  La mercancía se entrega desde la mochila y las monedas se pagan al completar
  el pedido. Los carteles muestran precio, existencias y fila llena.
- **Mochila:** 16 espacios compartidos, mejorables a 24 y 32. La guía indica
  cuándo llevar la carga a cada puesto. No se pierde un recurso por falta de lugar.
- **Leñador y cazador:** cuestan 60 y 120 monedas. Caminan, trabajan con su
  herramienta y llevan lo obtenido al depósito. Antes del tren, llevás esa carga
  a los puestos vos mismo. Cada trabajador tiene tres niveles.
- **Ferrocarril:** tres tramos de 90, 140 y 210 monedas forman un circuito
  visible. Al cerrarlo aparece la locomotora con dos vagones: carga en el depósito
  y descarga madera y carne en los puestos. Las filas compran esa misma carga.
  Dos mejoras posteriores aumentan velocidad y capacidad.
- **Ruta clara:** cuatro metas comerciales y el precio del pasaje aparecen en
  pantalla. La primera etapa exige 40 unidades vendidas, ambos trabajadores,
  tres tramos y un pasaje de 80 monedas. No exige esperar una ventisca. Viajar
  requiere una acción deliberada; los mercados anteriores siguen trabajando.
- **Guía:** puntos dorados, flecha con distancia, objetivo persistente y botón
  que cambia entre cortar, cazar, cargar y entregar. Comprar no abre tutoriales
  que bloqueen la partida. Hay sonido e indicadores de cosecha y pago.
- **Guardado:** conserva refugios y archipiélago, paquete Android y firma de
  prueba. Añade inventario comercial, monedas, pedidos parciales, empleados,
  tramos y carga del tren al guardado existente. Hasta dos horas de simulación
  al volver, sin volver a pagar un pedido completado.

## Verificación

`refuge_market_tests.gd` comprueba inventarios, pagos, capacidad, contratación,
caza compartida, regeneración, viajes del tren, archivos antiguos y datos dañados.
El recorrido de balance usa comandos normales, sin monedas ni empleados regalados;
su tiempo simulado omite los trayectos y no representa duración humana de juego.

`refuge_trade_touch_tests.gd` dirige el joystick con eventos de dedos, mantiene
las herramientas, entrega ambas mercancías, compra los empleados y los tres
tramos usando únicamente las ventas, y verifica ventas automáticas, carteles,
guardado y reanudación. Produce capturas del motor en 720×1280 y comprueba la
distribución también a 720×1600. Continúan las regresiones del movimiento y de
ambas campañas. Estas comprobaciones no sustituyen una prueba en teléfono físico.

APK de prueba ARM64: versión **0.22.0**, código **26**, paquete
`sv.apenalegaltech.wivoritrails`, misma firma para actualizar conservando la partida.
