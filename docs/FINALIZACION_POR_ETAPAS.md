# Wivori Trails — hoja de ruta de finalización por etapas

Fecha de línea base: 18 de octubre de 2026, rama `main`, versión 0.16.0.
Este documento deriva de los requisitos del proyecto «Revisión de idea de juego» y
las correcciones posteriores. No presupone que 0.16.0 tenga acabado comercial.

## Condiciones que NO pueden cambiar
- El perrito controlable es un **Scottish Terrier gris atigrado**, inspirado en
  el perro del creador, pero **no tiene nombre dentro del juego**.
- Los NPC no son terriers en serie: zorro, conejo, cerdo, pato y mapache tienen
  siluetas y comportamientos distinguibles.
- El control del jugador es manual y la cámara lo sigue; los ayudantes cumplen
  tareas contratadas sin sustituir el juego.
- El dinero de ventas se acumula en pilas visibles y se recoge personalmente
  o por recaudadores que lo llevan de verdad a tesorería.
- La progresión no acaba en un mercado: actividades agrícolas, talleres,
  granjas de animales, barco, pueblos e industria deben tener sentido económico
  y culminar en una meta verificable (Faro).
- Los letreros de caja, entrega, tesorería y mejoras deben ser claros, coloridos,
  de alto contraste, visibles por encima de techos y no amontonarse.
- Avisos de eventos cotidianos no pueden congelar continuamente la partida.
  Las presentaciones de **nueva etapa y objetivos clave** sí pueden usar
  tarjetas grandes (al menos el 75 % de la pantalla), con confirmación expresa.
- La referencia de calidad es la *riqueza visual y la legibilidad* de juegos
  como Township, NO la copia de sus modelos, iconos, pantallas o arte.
- El tamaño final puede superar cientos de MB si hace falta; nunca aumentar
  peso artificialmente ni sacrificar FPS, memoria o estabilidad sin beneficio.

## Estado técnico que ya existe en 0.16
- Godot 4.4.1, Android ARM64, package y firma estables.
- Protagonista original GLB, 17 huesos, 14 clips y atlas PBR de 1024.
- NPC de distintas especies; materiales y fuentes con licencia documentada.
- Mercado con doce capítulos, trabajadores, defensas y robos de mercancía.
- Venta, recaudación manual, dos cajas y conejo recaudador.
- Casa, café, molino, granjas, talleres y solares movibles.
- Transbordador con Wivori, Villa Miga, Puerto Nata y Bahía Farol;
  quince proyectos principales, cadenas de trigo/leche/huevos/carne y sus entregas.
- Guardado migrable v1–v8, pruebas de viaje, economía, colisiones y táctil.
Conservar esto es una precondición para todos los cambios.

## Etapa 1 — Auditoría de arte y animación del protagonista
**Trabajo a realizar**: revisión frontal, lateral y posterior sin obstáculos
en las capturas del motor; evaluación de hocico, orejas, barba, ojos, cejas,
postura, patas y rig; caminar/correr/cargar/entregar/cosechar/celebrar;
comparar proporciones sin usar modelos de terceros sin licencia.

**Actualizado en 0.16.1**: estudio de cámara real para inspección de héroe
y NPC sin edificios delante; señalización de mejoras visible al acercarse,
sin saturar la vista; supresión de interrupciones de pantalla repetidas por
cada mapache y cada cola llena; nueva prueba de arte automatizada.

**Pendiente de aceptación humana**: ver 360 grados y animaciones funcionando
durante juego móvil, corregir defectos observados, revisar estética frente a
referencias comerciales. El test de que existe un rig NO demuestra calidad artística.

**Criterio**: el perrito se reconoce inmediatamente como un Scottish Terrier,
los NPC no lo imitan y ningún elemento de la cara parece despegado;
mínimo clips de locomoción/control y acciones principales sin deslizamiento.

## Etapa 2 — Diseño gráfico de interfaz y señalización
Recrear botones, pictogramas y paneles como un sistema visual coherente.
Implementar carteles colgados encima de edificios, fuentes con personalidad,
tamaños escalados y contraste sobre fondos claros/oscursos.
Revisar en 720x1280 y 720x1600. Nada debe tapar el joystick ni las acciones.
Medir solapes con pruebas automatizadas; verificar manualmente las capturas.

**Criterio**: cada mejora se distingue sin depender de texto minúsculo;
caja/tesorería/entrega son reconocibles al caminar; no hay cajas flotantes
masivas ni avisos permanentes que vuelvan incontrolable la pantalla.

## Etapa 3 — Animaciones y recompensas visibles
Cosecha con fruto físico, mochila y llenado; entrega con movimiento de producto;
clientes comprando; monedas que quedan en pilas de cajas; recogida automática al
pasar Scottie cerca; recaudador caminando, cargando y entregando; robo y
recuperación visibles, con mensajera coneja gesticulando sin detener la partida.

**Criterio**: en cada acción se ve origen, trayecto y destino de los objetos.
No se acredita saldo duplicado al guardar/cargar, ni se roba una fruta invisible.
Oleadas de mapaches escaladas sin molestar cada 15 segundos.

## Etapa 4 — Mundo, pueblos, granjas e industria
Perfeccionar el escenario *existente* por distritos con composición, vegetación,
arquitectura diferenciada y oficios separados. Las granjas deben tener animales
reconocibles y animados; fábricas muestran procesos y productos. Los barcos
viajan a nuevos pueblos persistentes; cadena logística entre zonas.
La meta Faro se alcanza de forma jugable y queda señalada; tras ella
continúa el comercio opcional, no una monotonía de tareas repetidas.

**Criterio**: cada nuevo distrito aporta productos, decisiones, obstáculos y
recompensas visibles. Viajar ida/vuelta y recuperar la partida no pierde stock,
construcciones o trabajadores.

## Etapa 5 — Calidad y publicación experimental
- Importar Godot sin errores; correr todas las suites de regresión.
- Exportar APK ARM64 con el mismo package/firma y un versionCode nuevo.
- Tomar capturas *reales* del motor y comprobar que muestran el objeto correcto.
- Probar en dispositivo Android físico FPS, temperatura, memoria, 30 minutos
  de juego, multitáctil, pausa/reanudación, cambio de mapa, guardado.
- Auditar licencias y permisos de terceros.
- No pasar a `main` ni distribuir como versión final sin aprobar cada etapa.

## Regla de entrega
Para cada etapa registrar: archivos modificados, capturas o video real,
fallos reproducidos y corregidos, pruebas ejecutadas, APK reproducible y
limitaciones pendientes. Si la calidad aún es inferior al objetivo,
indicarlo expresamente, nunca presentar una escena técnica como arte final.
