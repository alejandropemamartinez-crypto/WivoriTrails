# Wivori Trails 0.18.0 — seis mapas y expediciones

Integra las etapas de arte, controles y campaña que se habían preparado sin
compilar. El protagonista conserva su control manual y no tiene nombre.

## Cambios jugables y visuales

- Seis escenarios persistentes: mercado, campos, granjas, bahía, fábricas y
  astillero. Hay 24 proyectos y 11 recetas; completar instalaciones y mejoras
  locales abre el siguiente escenario. Las partidas antiguas mantienen acceso.
- Forja añade empaques, conservas, kits y seis contratos de carga mixta.
  Aurora añade cuatro proyectos, barco mercante y tres expediciones distintas;
  completar las tres funda la red comercial y conserva el comercio posterior.
- Novedades voluntarias desde Mapas. Ningún encargo, compra disponible, cola
  llena ni producción terminada abre automáticamente una pantalla que pause.
- Tablero de pedidos ×2 de tamaño fijo con producto y cantidad separados.
  Cartel de entrega reducido y desplazado para dejar al personaje visible.
- Héroe exportado y revisado dentro del motor; ojos de superficie integrada,
  atlas sincronizado, orejas cortas y animación esquelética. NPC distintos.
- Conserva el paquete, el certificado de prueba y el guardado v8 compatible
  con v1–v8. Android ARM64, versión 0.18.0, código 19.

## Fallos corregidos durante la ejecución

- Dos inferencias de tipo inválidas en la interfaz de rutas y una variable
  duplicada en el catálogo impedían cargar la escena principal.
- Añadir mercancía de un mismo tipo invertía las instancias de su cesta;
  se conserva ahora el orden y se reutilizan las mallas existentes.
- Silos con nombres únicos para identificar ambos modelos construidos.
- Marcador de ruta sin sombra flotante. Estado final de campaña explícito,
  sin anunciar ampliaciones de flota que todavía no existen.
- La comprobación de transformaciones MultiMesh se ejecuta con gráficos
  activos: el servidor dummy de Godot no conserva sus matrices.

## Validación reproducible

Godot 4.4.1: importación y arranque reales; suites de economía, fabricación,
construcciones, contratos, robos, controles, guardado y migración. El recorrido
de dependencia de las islas originales cosecha y fabrica ingredientes reales;
los escenarios de cierre de Aurora usan reservas preparadas y verifican gasto,
consumo, avance temporal remoto y cobro único tras recargar.

Pruebas nativas de interfaz con toques y arrastres: joystick, dos dedos para
correr, cancelación, menús, compras e interceptación. Control manual y parada
al soltar el dedo en los seis mapas. Capturas nativas en 720×1280 y 720×1600,
incluyendo héroe frontal, perfil, espalda y poses de acción. Las capturas usan
partidas preparadas, no una sesión humana de campaña completa.

Android se exporta y verifica en CI, con logs y capturas en los artefactos de
la revisión. La firma estable permite instalar sobre la versión anterior sin
borrar el progreso. Es un APK de desarrollo, no una publicación en Google Play.
No se dispuso de un teléfono Android físico: manejo físico, FPS, temperatura,
batería, retención y balance con jugadores requieren esa evaluación posterior.
