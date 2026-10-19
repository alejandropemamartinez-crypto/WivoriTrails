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

### Avance técnico de la etapa 2 — rama sin compilación
- Rama de cambios: `feat/v017-stage2-ui-signage-no-build`, basada en la etapa 1.
- Títulos de misión ajustables en tamaño (Quicksand), explicación en dos líneas y botón de guía más compacto.
- Los paneles de compra cercanos se ocultan durante robos y alertas de la coneja, para no tapar una acción urgente.
- Carteles de mejoras elevados: pictograma particular (10 SVG ya existentes), letra más grande, precio y placa de alto contraste.
- Carteles de cajas, tesorería y encargos subidos por encima de los modelos.
- Segunda tanda de mejoras de interfaz **guardada sin compilar**:
  - Cada tarjeta de compra tiene ahora acento cromático por oficio, medallón con pictograma, título, beneficio, precio y estado de compra (disponible, faltante, bloqueada, conseguida).
  - Catálogo horizontal de nueve edificios con ilustraciones y tarjetas cromáticamente diferenciadas, coste y disponibilidad visibles.
  - En los pueblos de la Ruta al Faro, embarcadero, caja local y letreros de producción aparecen por encima de los edificios; el marcador del siguiente proyecto es un tablero de madera y no un círculo de suelo.
  - Menús de la ruta y la producción incorporan encabezados separados en tarjetas con tipografía Quicksand.
  - Se añadieron comprobaciones estáticas/de escena a `tests/art_direction_tests.gd` para ejecutarlas **después**, no ahora.
- **No se ejecutaron Godot, tests, capturas ni APK**, a solicitud del creador. Tampoco se fusionó con `main`. Estos cambios están sujetos a prueba funcional y revisión visual posteriores.
- Pendientes concretos de esta etapa: captura y lectura en 720x1280 y 720x1600, evitar solapes con el joystick y alerta de mapaches, inspeccionar escalas reales de letreros desde distintos ángulos, verificar accesibilidad táctil y rendimiento, corregir detalles artísticos detectados en las capturas.
- La calidad visual comparable a Township **no está acreditada**; requiere evaluación de los recursos 3D y las animaciones, además de la interfaz.

## Etapa 3 — Animaciones y recompensas visibles
Cosecha con fruto físico, mochila y llenado; entrega con movimiento de producto;
clientes comprando; monedas que quedan en pilas de cajas; recogida automática al
pasar Scottie cerca; recaudador caminando, cargando y entregando; robo y
recuperación visibles, con mensajera coneja gesticulando sin detener la partida.

**Criterio**: en cada acción se ve origen, trayecto y destino de los objetos.
No se acredita saldo duplicado al guardar/cargar, ni se roba una fruta invisible.
Oleadas de mapaches escaladas sin molestar cada 15 segundos.

### Avance técnico de la etapa 3 — rama sin compilación
- Rama: `feat/v017-stage3-physical-flows-no-build`, continuada desde la etapa 2 (sin fusionar).
- La compra animada de un cliente parte físicamente del comprador y termina en la caja correspondiente; el dinero sigue sin ser gastable hasta la recogida y finalización de su traslado.
- Nuevas trayectorias visuales de modelos de mercancía para manufactura, recogida de lotes, pedidos premium, despacho, almacén del barco y puestos de las otras islas.
- Se visualizan los ingredientes auténticos de cada receta; se eliminó el efecto anterior que mostraba manzanas sin importar el producto elaborado.
- El trigo cosechado se traslada visualmente hacia el protagonista y la confirmación aparece como rótulo flotante no modal.
- La bonificación de cosecha doble ahora genera dos objetos en vuelo, no uno solo. Se corrigió la guía que aún mencionaba un círculo de entrega.
- La caja local de cada pueblo muestra una pila de doce monedas que crece con la recaudación y desaparece al recogerla; la animación de cobro existente sigue usando el saldo único en tránsito.
- Se limitan las partículas/modelos de cada traslado a ocho para evitar ráfagas descontroladas en móviles.
- Nueva suite `tests/physical_flows_tests.gd` preparada para revisar saldos, existencia de modelos y ausencia de créditos dobles.
- **No se ejecutaron Godot, importación, pruebas, capturas ni compilación APK**, conforme a la solicitud. El código requiere validación antes de considerarse funcional.
- **Pendiente**: capturas auténticas y evaluación de continuidad origen-destino; verificar animaciones de todos los actos del personaje, defensa y recuperación del robo; medir rendimiento durante transporte masivo y descartar errores de importación, tipado o escenas. Sin validación no se da por finalizada la etapa 3.

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

### Avance técnico de la etapa 4 — primera entrega sin compilación
- Rama de trabajo: `feat/v017-stage4-region-identity-no-build`, nacida de la etapa 3 y separada de `main`.
- `scripts/region_identity.gd`: nueva composición visual por región, sin reconstruir los mapas persistentes ni alterar sus coordenadas de construcción. Villa Miga presenta surcos y pacas; Puerto Nata, praderas cercadas y barriles; Bahía Farol, carga, boyas, postes y luces de muelle.
- Juncos litorales agrupados mediante `MultiMesh` (90 instancias por distrito) y banderines con movimiento ligero. La utilería costera no altera obstáculos ni rutas.
- `scripts/archipelago.gd`: incorporación de la identidad al entrar en cada isla, destrucción al abandonarla, y líneas visuales de procesamiento con el producto correcto durante lotes activos de harina, alimento, pan, queso, carne y provisiones. Son accesorios visuales: el inventario y el tiempo de elaboración siguen usando el sistema original.
- Los animales que **ya hayan sido desbloqueados** por construcción reciben pequeños desplazamientos al caminar y pastar; se conservan los modelos, tamaños y corrales previos. No aparecen animales de granja antes de edificar su proyecto.
- `tests/region_identity_tests.gd`: suite añadida para revisar identidad de las tres islas, batching, presencia de maquinaria, animación animal, conservación de dinero e inventario y regreso al mercado.
- **Estado real**: código guardado, **sin** importar Godot, ejecutar pruebas, tomar capturas ni compilar. Esta etapa es parcial: sigue pendiente inspeccionar las escenas con el motor, corregir interferencias de props, probar FPS en Android, enriquecer arquitectura authored y revisar el recorrido completo del Faro. La suite añadida no equivale a prueba superada.

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
