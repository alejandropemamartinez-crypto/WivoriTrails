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


### Etapa 4 — segunda tanda de cambios (sin ejecución)
- Las seis pilas visuales de mercancías de Bahía Farol ahora dependen del stock **real** del almacén del barco; no aparecen contenedores llenos si no hay carga. El decorado no puede modificar inventario ni moneda.
- Los pedidos locales muestran productos de mayor demanda por región: +15 % de valor en productos característicos, y se respeta la vigía de Bahía Farol (+25 % cuando está construida). Son primas comerciales simples, sin alterar la cantidad vendida, créditos pendientes ni esquema de guardado.
- Se eliminan los avisos repetitivos de lotes concluidos por operarios automáticos; los lotes manuales anuncian su finalización de forma breve y no modal en la estación. El cartel de cada taller sigue indicando la mercancía lista.
- El guardado v8 lee y conserva si cada lote en curso fue iniciado por empleado o jugador, con valor seguro por defecto para partidas antiguas. La apariencia se reconstruye al entrar en cada isla; no se serializan nodos 3D.
- Ampliadas las pruebas **preparadas** para cubrir almacén vacío/lleno/vaciado, especialidades de pueblo, precios deterministas y producción silenciosa.
- **Sin validar en Godot:** compilación/parseo real de GDScript, comportamiento de la interfaz, capturas auténticas, obstáculos decorativos y rendimiento. No se ha generado APK ni fusionado la rama.
- **Siguiente intervención importante:** diseñar una expansión industrial jugable realmente distinta tras completar el Faro (cadena de productos y nuevo distrito persistente), no un simple cambio de color o una lista interminable de pedidos. Será una etapa propia porque exige probar migración de partidas, rutas y balance de progresión.

## Etapa 4B — Distrito Forja, después del Faro (rama independiente, no compilada)
- Rama: `feat/v018-industrial-expansion-no-build` (parte de etapa 4, **sin** fusionar con `main`).
- Se conserva íntegra la campaña original de **15 proyectos**: completar su inauguración habilita un quinto destino, **Distrito Forja**, sin reiniciar mercados, trabajadores, construcciones o el faro.
- Cinco inversiones nuevas y secuenciales: muelle industrial, empaquetadora, conservera, centro de logística y bolsa de comercio isleño. Cada una tiene coste, lugar y requisitos de productos transportados.
- Nuevas cadenas industriales: trigo y harina → empaques; empaques y provisiones → conservas; conservas, empaques y queso → kits de comercio. Las fábricas existentes siguen suministrando recursos.
- Se reutilizan modelos GLB legítimos de parcelas/mercancías (no hay cargas inexistentes), con **estructuras metálicas procedurales** añadidas para distinguir las máquinas. Es un primer acabado técnico, no arte comercial aprobado.
- Contratos industriales mixtos rotativos al terminar los cinco proyectos. La entrega consume ingredientes una sola vez; el pago queda en la caja de Forja y **solo es disponible tras recogerlo**. Hay seis combinaciones/recompensas definidas.
- `scripts/region_identity.gd` incluye un barrio portuario industrial con silos, aspas móviles, áreas de carga y contenedores; la representación del stock usa exclusivamente inventario real y exige haber construido el muelle industrial.
- Progreso almacenado de forma **aditiva** en la sección `route` del guardado v8: `industry_stage`, `industry_orders_done`, quinta caja de efectivo y nuevos lotes. Partidas anteriores carecen de estos campos, por lo que cargan con progreso industrial cero sin perder los quince proyectos del Faro.
- `tests/industrial_expansion_tests.gd` preparada (no ejecutada) para gates, viaje, proyectos, producción, recarga, entrega de contratos, efectivo en tránsito y ausencia de créditos duplicados. Actualizada además la expectativa de destino final en `tests/archipelago_tests.gd`.
- **Riesgos conocidos**: GDScript aún no se ha importado ni parseado con Godot; arquitectura industrial no ha sido inspeccionada mediante capturas auténticas; colisiones, rendimiento móvil y balance de ingresos de largo plazo no se han medido. No se generó APK ni se ejecutó ninguna prueba.
- **Siguiente bloque**: auditar en el motor la integración de las etapas 1–4B, corregir fallos encontrados, evaluar arte industrial y transiciones y preparar una compilación **solo cuando el creador autorice la etapa de pruebas**.

## Etapa 5 — Calidad y publicación experimental
- Importar Godot sin errores; correr todas las suites de regresión.
- Exportar APK ARM64 con el mismo package/firma y un versionCode nuevo.
- Tomar capturas *reales* del motor y comprobar que muestran el objeto correcto.
- Probar en dispositivo Android físico FPS, temperatura, memoria, 30 minutos
  de juego, multitáctil, pausa/reanudación, cambio de mapa, guardado.
- Auditar licencias y permisos de terceros.
- No pasar a `main` ni distribuir como versión final sin aprobar cada etapa.

### Primera auditoría estática de integración — rama sin compilar
Rama: `feat/v018-stage5-integration-audit-no-build`, basada en la expansión Forja.
**No se ejecutó Godot, pruebas, importación, captura ni APK**.

Correcciones incorporadas:
- El objetivo industrial ya no dirige a una caja sin los productos necesarios. Se guía al jugador hacia la receta del ingrediente faltante, su producción o el transbordador hacia otra isla. La entrega sigue siendo manual.
- Los tutoriales cotidianos de compraventa, fabricación y recogida ya no abren un diálogo modal distinto por cada producto. Tampoco lo hace cada mejora que se vuelve asequible; conserva el aviso HUD una sola vez por precio. Las presentaciones de capítulos, destinos y construcción importante continúan con confirmación.
- El botón principal `RUTA AL FARO` pasa a `DISTRITO FORJA` tras completar quince proyectos y conserva ese nombre cuando se vuelve a cargar el juego.
- Se evitó fijar automáticamente la guía de la Ruta del Faro cada vez que se carga una partida ya completada; el usuario sigue pudiendo elegir los objetivos del mercado principal.
- Los árboles de la plantilla de isla no se colocan sobre los silos industriales, y los edificios decorativos de Forja emplean modelos de depósitos y talleres en lugar de cuatro casas rurales.
- La maquinaria decorativa de Distrito Forja se desbloquea visualmente con los proyectos pagados: plataforma del muelle, silos de empaquetado, ventiladores de la conservera, contenedores logísticos y remate del centro comercial. Rehacer el entorno decorativo **no** reinicia fábricas ni inventarios.
- Preparadas pruebas adicionales `tests/stage5_integration_tests.gd` y ampliada `tests/industrial_expansion_tests.gd` para rutas de abastecimiento, disponibilidad de fábrica, progresión visible, guardado y ausencia de modales cotidianos.

**Pendientes antes de dar aprobación**: parseo e importación Godot 4.4.1, ejecutar todas las suites, revisar en capturas del motor solapes reales, rutas de navegación y colocación de objetos, probar a dos tamaños de pantalla, mirar animaciones del protagonista/NPC, FPS y persistencia en Android físico, auditoría de licencias. Los cambios descritos son una implementación sin prueba funcional.

### Auditoría 5B — dinero entre islas, guías y colisiones (sin compilar)
Rama: `feat/v018-stage5b-transport-cash-qa-no-build`, derivada de la auditoría 5A, no fusionada a `main`.

- Se corrigió un defecto concreto: las monedas en tránsito de las **cajas locales** se dibujaban y animaban como hijas del sistema de cobros de Wivori, que está oculto y desactivado durante los viajes. Ahora `_fly_money` crea los objetos temporales y sus tweens en la ruta persistente, visible y activa en los otros pueblos. No se altera la suma de cobro pendiente ni el momento de acreditarla al monedero.
- El botón de contratos industriales usa la misma fuente de objetivos que la guía HUD: con ingredientes faltantes señala la fábrica/cosecha o abre los destinos del barco, y ya no lleva engañosamente a la caja vacía.
- La decoración sólida de las islas (carros, barriles, carga portuaria, muelles de Forja, silos y contenedores) comunica sus huellas al sistema de navegación. Antes los actores podían caminar *a través* de utilería visible. Se quitan las colisiones antiguas antes de regenerar la decoración al construir, para evitar obstáculos fantasma o duplicados.
- Habitantes y operarios ahora consultan la elevación del terreno de cada isla; los operarios dentro de un nodo de taller traducen su posición local a coordenadas globales para no hundirse en el suelo.
- Se eliminó de la alerta del puesto vacío la referencia ya obsoleta a un «círculo dorado».
- Añadida la suite `tests/cross_island_cash_tests.gd`, que define pruebas de visibilidad de monedas, viaje de Forja a Wivori, recarga durante dinero en vuelo y ausencia de duplicaciones. Ampliadas `tests/industrial_expansion_tests.gd` y `tests/region_identity_tests.gd` con huellas de colisión, liberación de obstáculos y anclaje de NPC.
- **Estado:** fuente guardada; no se ha ejecutado Godot, las suites, una importación de escenas, Android ni la compilación de un APK. Las pruebas preparadas son especificaciones para la fase de validación, no aprobaciones. Siguen pendientes evaluación artística, capturas reales, rendimiento y localización física de posibles colisiones residuales.

### Etapa 5C — arquitectura propia para la industria (código, sin compilación)

- Rama de trabajo `feat/v018-stage5c-authored-factory-art-no-build`, derivada de la etapa 5B, separada de `main`.
- Nuevo prefabricador visual `scripts/factory_facade.gd`: elimina la misma pareja de tanques genéricos que aparecía en **todas** las industrias; cada una recibe ahora silueta y acción identificables.
- **Muelle industrial**: grúa pórtico cobriza con travesaño, riel, cable, gancho y carro deslizante.
- **Empaquetadora**: tres cubiertas inclinadas de tipo diente de sierra, banda, paquetes y prensa vertical móvil.
- **Conservera**: dos depósitos metálicos con chimeneas, puente de tuberías, conservas selladas y vapor translúcido suave (material compartido con transparencia real).
- **Centro de logística**: dos portones enrollables con lamas y dinteles, cinta y palé animado, sin inventar stock real adicional.
- **Centro comercial**: columnas, cornisas, reloj circular de fachada y manecilla giratoria; aspecto cívico diferente del industrial.
- Cada fachada utiliza seis ventanas en una **MultiMesh** compartida para evitar dibujar seis mallas independientes. Los movimientos procedurales usan delta de fotogramas y no alteran inventario, dinero, progreso o obstáculos.
- Se orientaron las ventanas, portones y reloj hacia el **frente real de acceso (Z positivo)** que utiliza la cámara del juego; colocarlos en la fachada trasera habría ocultado los detalles tras los modelos importados. Se agregó una aserción de regresión para su orientación.
- En la escena `scripts/archipelago.gd`, los componentes nuevos emergen con la animación de construcción; al volver a una isla se regeneran como decoración de las fábricas pagadas, conservando la lógica de guardado.
- Nueva batería **preparada sin ejecutar**: `tests/factory_facade_tests.gd` para cinco firmas visuales diferentes, movimientos reales, ventanas instanciadas, aislamiento económico y presencia en construcciones adquiridas.
- **Limitación de calidad**: son diseños 3D estilizados añadidos por código a los modelos GLB existentes; no equivalen por sí solos a arte comercial de nivel Township, ni fueron vistos en capturas de Godot. Falta revisar proporciones, sombras, materiales, interferencias con edificios y fluidez en Android.
- **No se importó Godot, ejecutaron pruebas, generaron capturas ni compiló APK**. Próxima fase: auditoría visual verdadera, rediseño de elementos que continúen pareciendo bloques y pruebas de extremo a extremo antes de fusionar.

### Etapa 5D — identidad arquitectónica de los pueblos originales (sin compilación)
- Rama `feat/v018-stage5d-village-art-no-build`, nacida de la etapa 5C e independiente de `main`.
- Se añadió `scripts/village_facade.gd`, un sistema que asigna elementos originales y específicos a **doce edificios ya existentes**, sin construir copias nuevas, gastar monedas ni modificar el inventario.
- **Villa Miga**: espantapájaros y cestas del campo; zona de molienda y sacos en el molino; panadería con toldo de franjas y exposición de panes; gallinero con nidos, huevos y perchas.
- **Puerto Nata**: lecheras y campana en el establo; quesería con toldo, piezas de queso y botellas; corral con comedero; carnicería como tienda de productos empacados sin imágenes violentas.
- **Bahía Farol**: almacén con bolardos y tarima, cocina de provisiones, vigía con señales náuticas y base del faro con balizas. Se mantiene el haz luminoso y la animación originales del faro.
- Los toldos, carteles físicos y banderines poseen materiales de colores diferenciados; banderines animados reciben tiempo delta y se reconstruyen al visitar cada isla. Las nuevas piezas se sitúan ante la fachada de cada modelo importado y aparecen con la compra del proyecto.
- La vegetación cosechable y pacas de Villa Miga, la pradera de ganado y los barriles de quesería de Puerto Nata solo se muestran cuando el jugador construye efectivamente sus instalaciones. Cada proyecto adquirido refresca la identidad exterior, retirando antes las huellas de navegación anteriores para evitar obstáculos fantasma.
- Se preparó `tests/village_facade_tests.gd` (no ejecutada) para revisar las doce identidades, tres destinos, cambios visibles al construir, animación, permanencia de los puntos de producción, llegada al muelle, conservación de inventario/monedas y regreso a Wivori.
- **Sin evaluación visual real**: el trabajo sigue siendo arte de apoyo generado dentro del motor y modelos preexistentes, no nuevos assets GLB esculpidos por artistas. Está por comprobarse proporción, accesibilidad, superposición con modelos originales, lectura en móviles, FPS y recepción de animaciones. No se corrió Godot, pruebas funcionales, capturas ni APK.

### Etapa 5E — protagonista y movimiento de NPC (fuente, sin compilar)
Rama: `feat/v018-stage5e-character-motion-no-build`, basada en 5D y sin fusionar a `main`.

- Nuevo módulo `scripts/character_motion.gd`: política de presentación de movimientos por especie — amplitud de atención al mirar, ritmo de pasos de conejos/patos/cerdos/zorros/mapaches, balanceo de cola, seguimiento de orejas y giros suavizados; **no cambia** aceleración de joystick, velocidad máxima, economía, navegación ni el esquema de guardado.
- `scripts/actor.gd`: reutiliza los esqueletos importados y clips GLB originales. Resuelve y **almacena** los índices de huesos de cabeza, orejas, ojos, cola y brazos una vez al crear cada actor, evitando búsquedas repetidas durante el fotograma.
- La cara reacciona ligeramente mientras el personaje está quieto; su torso respira en un rango mínimo sin modificar los pies ni la sombra de contacto. Las animaciones de carrera, marcha, giro y mochila transicionan según velocidad realmente observada, y se ignoran saltos de posición causados por viajes o restauraciones.
- Durante la marcha, los ojos usan **huesos reales del rig** para parpadear sin piezas flotantes. El parpadeo ya animado del clip `idle` se conserva y no recibe un segundo parpadeo superpuesto.
- Los operarios de taller reciben `face_direction_yaw(PI)`; antes se fijaba `rotation.y` pero su orientación preferida quedaba en cero y en el siguiente fotograma podían girar incorrectamente.
- **Escultura fuente** `art/source/build_hero.py`: ajustes del hocico, mejillas, iris y orejas erguidas; tonos gris atigrado y manchas suaves pintadas en la malla, sin bigote claro excesivo ni barba de schnauzer. Se conserva el modelo original de perrito sin nombre, pañuelo, rig y 14 clips.
- **Advertencia importante:** la escultura se modificó únicamente en el **script fuente de Blender**, todavía **no** en `assets/models/hero.glb`, porque en esta etapa el autor indicó no generar compilaciones ni exportaciones. El cambio de anatomía se verá en el juego **solo después de una futura exportación del arte**, que deberá inspeccionarse visualmente antes de integrarla.
- Añadida `tests/character_motion_tests.gd` para verificar decisiones de clips, 5 especies diferenciadas, giro de operarios, ojos/orejas y carga visible. Preparada pero **sin ejecutar**. Es necesario observar 30+ minutos de navegación, idle/caminata y animación en Godot/Android para aprobar el acabado.
- **Estado real:** cambios de fuente guardados en GitHub; sin importación de Godot, pruebas ejecutadas, render del personaje actualizado, exportación del modelo, APK ni modificación de `main`.

### Etapa 5F — coherencia de mercancía en protagonista y NPC (solo código)
- Rama de trabajo: `feat/v018-stage5f-character-cargo-coherence-no-build`, derivada de la etapa 5E y no fusionada a `main`.
- Se detectó una incoherencia visual: los personajes cargaban inicialmente cinco frutas de demostración aunque no hubieran comprado, recogido o robado nada; el protagonista además podía mostrar únicamente el **primer** recurso de las islas mientras su mochila contenía otros productos diferentes.
- Ahora los clientes, empleados y mapaches nacen con la carga visual **vacía**. Los clientes que realmente transportan verduras y los ladrones que se llevan productos reciben modelos correspondientes a ese tipo específico.
- En `scripts/actor.gd`, `set_visible_cargo(contents)` acepta únicamente productos reconocidos, calcula una presentación proporcional a las **cantidades realmente disponibles**, y muestra un máximo de seis objetos importados. Combina frutos del mercado original con trigo, harina, leche, queso, pan, huevos, carne, provisiones y mercancías industriales; los modelos industriales nuevos se resuelven mediante los GLB existentes `goods_parcel`, `goods_provisions` y `goods_crate`.
- `scripts/game.gd` incorpora una única sincronización de visuales al cosechar, entregar y cargar partidas. `scripts/archipelago.gd` utiliza esa función después de recoger, depositar, fabricar o vender; ya no añade un producto aislado delante del personaje mientras oculta los demás. **No cambia** el contenido de inventarios, precios, tiempos de fabricación, pagos, niveles ni el guardado de versión 8.
- La representación usa una firma estable y conserva los nodos GLB cuya carga **sigue siendo la misma**, evitando liberar y reinstanciar toda la mochila tras cada recolección. La pantalla no dibuja seis objetos cuando el personaje solo lleva uno.
- Preparada la suite `tests/character_cargo_tests.gd` (sin ejecutar) para cubrir manos vacías, productos realmente transportados, mezclas de frutas y mercancía industrial, cambios incrementales, reutilización de objetos 3D, ladrones, carga y restauración de partidas con inventarios procedentes de distintas islas, y ausencia de mutaciones económicas.
- **No validado:** carga y parseo reales en Godot, importación de modelos, posiciones visuales durante animaciones, huellas de colisión, visualización en móviles y rendimiento. No se generó APK, no se ejecutó prueba, no se reexportó el héroe ni se tocó `main`.
- **Próximo bloque:** auditar las transiciones de `AnimationPlayer` y `Skeleton3D` con escenas reales, revisar carga y parpadeos sobre cada NPC e inspeccionar la escultura nueva exportada solo en la etapa de validación autorizada.

### Etapa 5G — fallos reales detectados por auditoría de código (sin compilar)

Rama: `feat/v018-stage5g-integration-fixes-no-build`, creada sobre la etapa 5F, sin fusionar a `main`. Esta etapa **no añade escenarios ni decoraciones**: corrige pérdida de progreso y coherencia entre inventario y personajes.

1. **Cantidades falsas en NPC.** Antes, `set_cargo_kind()` creaba automáticamente cuatro modelos de productos aunque el comprador o mapache llevara cero, uno o dos; `set_carry()` únicamente ocultaba/mostraba el bloque. Ahora seleccionar el tipo no añade productos imaginarios y cada actualización dibuja `min(cantidad_real, 4)` unidades (0 = cero mallas). Se preserva el método usado por ayudantes, clientes y ladrones.
2. **Reutilización entre reordenamientos de la mochila.** Antes se comparaba el recurso 3D con el índice anterior, de modo que añadir una nueva clase de mercancía podía destruir y reinstanciar modelos iguales desplazados de posición. Ahora se agrupan las escenas existentes por la ruta real de su GLB y se reutilizan por **tipo de producto**, sin importar su nueva posición; solo se importan unidades adicionales y se liberan sobrantes.
3. **Riesgo de pérdida silenciosa al cargar.** La lectura `route.load_state()` aplicaba al inventario de mano de cada producto un máximo variable `max_capacity - _total_bag()`, a medida que iteraba las mercancías. Una partida legítima con cosecha principal y productos de varias islas podía perder unidades en el momento de restaurar. La carga respeta ahora todas las cantidades válidas persistidas (acotadas a 100 000 por producto); el límite de mochila se mantiene para **nuevas cosechas/recogidas** y una partida antigua temporalmente sobrecargada debe depositar mercancía antes de añadir más.
4. **Modelos innecesarios por personaje.** Antes el protagonista, todos los clientes y mapaches importaban cada uno un modelo 3D de bolsa de dinero aun estando inactivos. Ahora solo se instancia `money_bag.glb` en el recaudador que llama a `set_money_carry()`. Su animación y el flujo de cobro continúan intactos.
5. **Regresiones preparadas pero no ejecutadas.** Ampliado `tests/character_cargo_tests.gd` con pruebas de cantidades físicas de NPC, ausencia de productos antes de comprar/robar, preservación de nodos durante reordenamientos, importación diferida de bolsas y carga de un guardado v8 con contenido válido que excede temporalmente la capacidad. La batería `tests/production_tests.gd` sigue verificando el cobro real del recaudador cuando se autorice ejecutar pruebas.

**Riesgos que quedan:** el código no ha pasado el parser ni el importador Godot 4.4.1; no se probaron animaciones, materiales, cruces de isla ni FPS reales. La nueva escultura del perrito sigue sin exportarse a `hero.glb`. Aún no se construyó APK y `main` permanece intacta.

### Etapa 5H — navegación y animaciones de efectivo entre islas (fuente, no compilado)

Rama `feat/v018-stage5h-money-navigation-audit-no-build`, derivada de la etapa 5G. No se modifica `main`.

- **Aislamiento visual de las monedas por destino:** el código anterior creaba las monedas animadas de las cajas, ventas y recogidas como hijas de la ruta global, visible en todos los escenarios. Si se viajaba con un pago todavía animándose, esas monedas podían aparecer flotando en las mismas coordenadas del pueblo siguiente. Ahora `scripts/cash_economy.gd` crea un contenedor transitorio por índice de región (Wivori, Villa Miga, Puerto Nata, Bahía Farol, Distrito Forja). Solo se muestra el contenedor del pueblo actual; el resto puede completar sus animaciones oculto.
- **Los valores contables no cambian:** siguen siendo las cajas pendientes, los cobros en vuelo y la tesorería quienes determinan los saldos. Un viaje no duplica dinero, no adelanta pagos y tampoco borra cobros legítimos. Los contenedores de efectos son meramente visuales; no se serializan.
- **Orden de restauración:** `scripts/game.gd` carga los datos del archipiélago antes de reconstruir el dinero en tránsito, para conocer la región donde debe aparecer el efecto. `scripts/archipelago.gd` limpia la indicación temporal `restore_region` una vez restaurado el destino y actualiza qué contenedor es visible después de cada travesía. Esto evita que al volver más tarde a Wivori se confundan las monedas nuevas con las del destino antiguo.
- **Bancos sólidos en los pueblos:** las tres bancas decorativas de cada región incorporan huellas reales al mapa de navegación; antes eran mallas sin obstáculo, permitiendo a residentes y protagonista atravesarlas. Se reconstruyen con la navegación del propio pueblo y no afectan al mapa de Wivori.
- Se extendió `tests/cross_island_cash_tests.gd` (no ejecutado) con escenarios de dinero retenido al cargar una partida desde Forja, cambio de visibilidad de los efectos al navegar a Villa Miga, colisiones de las bancas, retorno a Wivori y ventas realizadas después del regreso.
- **Estado:** revisión del código fuente y tests preparados exclusivamente. Godot 4.4.1 aún no ha parseado/importado estos cambios; no se ejecutaron suites, no se tomaron capturas y no se generó APK. Sigue pendiente comprobar que las animaciones de efectivo y la navegación coincidan visualmente con sus modelos en Android.

### Etapa 5I — operarios, fabricación remota y frecuencia de guardados (sin ejecutar Godot)

Rama `feat/v018-stage5i-worker-processing-no-build`, continuación directa de la etapa 5H y sin fusionar a `main`.

- **Mochila visual actualizada solamente cuando hay cambios reales:** `scripts/archipelago.gd` regeneraba la representación de los productos transportados en cada `tick(delta)` (hasta 60 veces/segundo), incluso al caminar sin fabricar o recoger nada. Ahora se actualiza al construir (consumir materiales), fabricar (consumir ingredientes), recoger resultados, cosechar trigo, depositar mercancía, vender productos o entregar contratos; también se reconstruye al cargar la partida. Si la cantidad no cambió, la firma del cargamento reutiliza las escenas GLB ya presentes.
- **Inicio automático sin un guardado completo por cada trabajador:** `start_batch(key,true)` podía escribir y respaldar el archivo v8 cada vez que alguno de los once tipos de talleres iniciaba trabajo, multiplicando las escrituras en Android. Los lotes automáticos ahora piden un autosave agrupado (plazo máximo de dos segundos mediante el temporizador ya existente `g.save_timer`), mientras que los lotes iniciados manualmente conservan su guardado inmediato.
- **Fin de lote y trabajadores pausados:** al terminar un proceso, se agenda también un guardado próximo, incluso cuando el trabajador está pausado o ya no hay ingredientes para comenzar otro lote. Pausar impide empezar nuevos lotes, pero permite acabar el trabajo que ya consumió sus insumos; así no se pierden materiales.
- **Fabricación que continúa durante los viajes:** antes `tick(delta)` retornaba durante la animación de transbordador **antes** de actualizar los tiempos de los talleres, por lo que quedaban congelados durante la travesía. Se adelantó exclusivamente la actualización de lotes y el inicio legítimo de trabajos automáticos al control de navegación del barco; los cobros, recogidas, cosechas e interacciones personales continúan deshabilitados mientras se viaja. El test incorpora un lote de pan pagado con harina real que termina a bordo y persiste tras volver a Wivori.
- **Estado de cada máquina legible:** el letrero del taller ya no muestra «0 s» cuando está detenido. Distingue **PREPARAR LOTE**, **OPERARIO DISPONIBLE**, **EN PROCESO**, **¡LISTO!**, **OPERARIO PAUSADO** y **SIN INSUMOS**, sin interrumpir al jugador con cuadros de diálogo. La nueva suite comprueba esas transiciones.
- **Ningún cambio de economía:** permanecen los tiempos de producción, la cantidad por receta, el coste de contratar, los almacenes, los límites de producto listo y el viaje físico para recoger los resultados. El operario remoto usa únicamente recursos del almacén del barco; no puede sustraer el trigo transportado en la mochila del jugador.
- Se preparó `tests/worker_cross_region_tests.gd`, **sin ejecutar**: contrato de pruebas para producción fuera de la isla actual, inputs descontados una sola vez, pausas y reanudaciones, fin de lotes, recuperación v8 en Puerto Nata, movimiento al molino para recoger harina y actualización inmediata de la mochila al iniciar un lote manual.
- **Pendiente:** probar el estado de los operarios al cambiar de isla, visualizar los indicadores de fábrica, medir cuánto ahorran realmente los guardados agrupados, vigilar los 8 segundos normales de autosave y examinar el rendimiento/consumo de batería en Android. Sin parser Godot, importación, ejecución, screenshots, APK ni modificación de `main`.

### Etapa 5J — integridad del guardado, rigs y transacciones durante viaje (fuente sin ejecutar)

Rama `feat/v018-stage5j-integration-hardening-no-build`, basada en 5I; `main` intacta.

1. **Mochila principal sin pérdida silenciosa:** después de reparar la restauración de productos de las islas en la etapa 5G, la ruta central `game._load_progress()` todavía leía `stash` con un límite decreciente `max_capacity - total_cargado`. Un guardado v8 legítimo con dos frutas distintas, o una capacidad reducida, perdía unidades durante la lectura. Se cambió a un límite de seguridad fijo de 100 000 por clase de fruta al **cargar**; el límite normal de la mochila sigue aplicándose a nuevas cosechas, entregas y recogidas. `tests/character_cargo_tests.gd` incorpora un caso en el que tomate, arándano y productos de las islas exceden temporalmente la capacidad, sin perder nada.
2. **Gestos acumulativos de los personajes:** `actor._secondary_motion()` añadía rotaciones a la pose de cabeza, orejas y cola y escalaba los huesos de los ojos después de cada avance de animación. Si un clip GLB no contiene pistas explícitas de uno de esos huesos, el desplazamiento podía acumularse indefinidamente (cola torcida, ojos progresivamente aplastados). Se guarda la pose animada anterior a los gestos y se **restaura antes del siguiente avance de AnimationPlayer**, conservando las animaciones originales de cada especie. `tests/character_motion_tests.gd` define un ensayo de 240 fotogramas para comprobar que cabeza y ojo vuelvan exactamente a su pose anterior.
3. **Prohibición real de intercambios mientras navega el barco:** `route.tick()` dejaba de procesar las interacciones de proximidad durante `sailing`, pero un botón que aún recibiera eventos podía llamar directamente a `deposit()`, `improve()`, `hire()`, `pickup()`, `build_project()`, `sell_bundle()` o `fulfill_industry_order()`. Todas esas acciones comprueban ahora `sailing>0`. La fábrica automática sí sigue llamando `start_batch(key,true)` y avanzando sus temporizadores; el inicio **manual** de lotes está expresamente bloqueado. `tests/worker_cross_region_tests.gd` prepara comprobaciones de depósito y compra pagada durante cada travesía.
4. **Sin cambios estructurales:** se conserva el formato de guardado v8, las recetas y precios, los modelos importados, las cinco islas, el movimiento manual y los saldos en efectivo.

**Validación pendiente:** ninguna suite ha sido ejecutada; las comprobaciones de código estático solo describen los casos que pretende cubrir la implementación. Continúan pendientes parsing/importación en Godot 4.4.1, juego manual, inspección de los huesos y luces con los modelos reales, prueba de autosave y recuperación en Android, rendimiento y APK. No se compiló ni fusionó a `main`.

### Etapa 5K — integridad de recursos, carga segura e importación (sin compilación)

Rama `feat/v018-stage5k-resource-startup-qa-no-build`, derivada de 5J. No se ejecutó ninguna acción de GitHub ni prueba de Godot; se conserva `main`.

- **Auditoría sobre árbol real de GitHub:** se enumeraron los 29 scripts de juego y se confrontaron 66 referencias literales `load/preload("res://...")` con los archivos verdaderamente presentes. **Resultado de esa revisión textual:** ninguna de las 66 rutas referenciadas está ausente. Las llamadas con nombres de modelos **concatenados dinámicamente** se comprobarán en el nuevo test de inventario 3D: no pueden garantizarse solo con buscar cadenas literales.
- **60 modelos GLB y 17 recursos de arranque:** se agregó `tests/resource_startup_tests.gd`, con un inventario exacto derivado de los 60 archivos `assets/models/*.glb` existentes; además incluye escena principal, icono, tipografías, shaders y siete pictogramas de letreros. Cuando se autorice ejecutar Godot, comprobará `ResourceLoader.exists`, que cada importación GLB produzca un `PackedScene` con raíz `Node3D`, que los seis personajes animados conserven `Skeleton3D`/`AnimationPlayer` y que las referencias reales de TODOS los proyectos, recetas, productos, ganadería y mochila apunten a un archivo registrado. La prueba está **preparada, NO ejecutada**.
- **Fallos de carga dinámica controlados:** `scripts/art_library.gd` y `scripts/actor.gd` antes hacían `load(...).instantiate()` sin comprobar si el recurso existía, era realmente un `PackedScene` o tenía raíz `Node3D`. Ahora emiten un error explícito indicando la ruta concreta y devuelven un contenedor neutro con nombre de error para evitar una excepción fatal. No se insertan casas genéricas ni bienes falsos como supuestos recursos sustitutos.
- **Materiales GLB de personajes:** `scripts/actor.gd` antes asumía que la primera `MeshInstance3D` tenía material `StandardMaterial3D` y textura `albedo`. Ahora busca una superficie importada texturizada y solo aplica el shader de vestuario cuando esa textura existe; de lo contrario, conserva el aspecto original del GLB. Esto reduce el riesgo de personajes oscuros por un atlas ausente y evita un acceso a material nulo.
- **Pictogramas:** `scripts/world_sign.gd` comprueba que el archivo SVG de cada símbolo esté presente; ante un símbolo inexistente, deja error de diagnóstico y utiliza la señal original `deliver.svg`. La batería comprueba expresamente `star.svg`, utilizado por los letreros de construcción.
- **Paquete Android:** inspección de lectura de `export_presets.cfg` confirmó que el filtro exporta `all_resources` y excluye las pruebas, herramientas y archivos Blender, sin excluir los GLB de ejecución. **Inconsistencia pendiente de lanzamiento:** `export_presets.cfg` declara versión `0.16.1`, mientras que el flujo de publicación y el README todavía se refieren a `v0.16.0`. Corregir en una futura etapa de empaquetado **después de validar la versión**, no generar ahora versiones ni APK con numeración engañosa.
- **Límite de lo comprobado:** la presencia de rutas y la sintaxis elemental de archivos no demuestran que Godot pueda parsear GDScript, importar cada GLB, renderizar materiales/rigging o arrancar un Android. Se requiere esa validación antes de declarar el juego estable o publicable. No se ha activado ninguna workflow de compilación ni abierto PR.

### Etapa 5L — auditoría de tipos y recursos enlazados (código, sin compilar)

Rama `feat/v018-stage5l-script-type-and-test-qa-no-build`, continuación de 5K. Mantener `main` sin cambios, sin iniciar workflows de Android y sin recompilar el juego.

- **Tipos GDScript de importación:** `actor.gd`, `art_library.gd` y `tests/resource_startup_tests.gd` cargaban archivos GLB en una variable declarada `Resource`, pero más adelante requerían métodos propios de `PackedScene` como `instantiate()`. El tipo del recurso se comprueba explícitamente `as PackedScene` antes de invocar el método; la caché dinámica también se verifica antes de su uso. Esto reduce el riesgo de un fallo de análisis estático o de recurso incompatibile; solo el parser real de Godot puede confirmar el resultado.
- **Materiales específicos de GLB:** al optimizar las mallas se consultaba `albedo_texture` sobre una variable tipada como `Material`, que no define esa propiedad. Las superficies se convierten de forma segura a `StandardMaterial3D` y las que usen otro tipo se excluyen de la optimización, conservando su diseño original. Esto evita también el acceso nulo cuando un modelo tenga otro material.
- **Mensajera de alertas:** `rabbit_warning.gd` usaba `load("rabbit.glb").instantiate()` sin validar y asumía que los clips `alert` y `surprise` estaban siempre presentes. Ahora usa la biblioteca 3D validada y solo configura/reproduce los clips disponibles; de faltar uno, registra advertencia y utiliza la animación de reposo cuando exista. No se sustituye el personaje por una silueta genérica.
- **Íconos de hitos y mejoras:** `milestone.gd` valida el SVG del capítulo antes de cargarlo y conserva un icono de estrella como alternativa. `world.gd` valida de igual forma los diez pictogramas de las casetas de mejoras y, cuando falta alguno, utiliza `shop.svg` con una advertencia. `tests/resource_startup_tests.gd` audita las diez correspondencias entre los modelos `booth_*`, los iconos SVG y las claves reales de `town_layout.gd`, además de las 60 escenas GLB.
- **Alcance de la revisión:** se inspeccionaron las llamadas dinámicas a recursos e instanciaciones en los 29 scripts del juego. Las nuevas pruebas son especificaciones **pendientes de ejecutar** y no se han tomado capturas ni confirmado las animaciones en Android. No se modifica el formato v8, precios, movimiento, modelo 3D del protagonista ni numeración del paquete.

**Siguiente prioridad:** validación con parser/importador Godot 4.4.1 y prueba real de las 19 baterías de regresión del proyecto (cuando se autorice ejecutar), después revisión visual de escenas y rendimiento Android. El código fuente no equivale todavía a un APK aprobado.

### Etapa 5M — integración real entre retrato 3D, viewport y materiales de NPC (solo fuente)

Rama `feat/v018-stage5m-cross-script-qa-no-build`, derivada de la 5L. Ninguna compilación, importación de Godot, prueba ejecutada, publicación o alteración de `main`.

1. **Error de tipos heredado de la etapa 5L:** `RabbitWarningBanner._ready()` llamaba `Art.place(portrait_view,"rabbit")`, pero `Art.place(parent: Node3D)` no admite `SubViewport`, que es un `Viewport`/contenedor 3D y **no** hereda de `Node3D`. Eso podía impedir el análisis de GDScript aunque el modelo y su ruta existieran. Se reemplazó por el cargador comprobado `MarketActor.model("rabbit")` y `portrait_view.add_child(actor)`. Con ello se conserva la malla importada y su `Skeleton3D`/`AnimationPlayer`, sin reutilizar equivocadamente un constructor de objetos de escenario.
2. **Prueba específica del retrato:** añadido `tests/rabbit_portrait_tests.gd`, aún sin ejecutar. Comprueba el árbol de nodos (el modelo es hijo del `SubViewport`), la ruta real de `rabbit.glb`, la textura y el render transparente, las fases de alerta/aproximación, la recuperación de mercancía, la flecha textual de peligro, la ausencia de diálogo modal y la suspensión del viewport invisible para ahorrar batería.
3. **Superficies y uniformes de NPC:** `MarketActor._find_mesh()` elegía la primera malla cuya **superficie 0** tenía una textura. El GLB puede contener ojos/metales antes que el tejido texturizado y más de una superficie. Ahora busca entre **todas las superficies** de cada malla importada, memoriza `head_surface_index` y aplica el shader de ropa únicamente a la superficie de atlas identificada. Conserva las demás superficies y el aspecto original del protagonista. Se añadieron comprobaciones a `tests/resource_startup_tests.gd` para confirmar la existencia de atlas real en las seis especies y que los cinco NPC pinten la superficie elegida con `ShaderMaterial`.
4. **Auditoría estática complementaria:** se examinaron las llamadas `Art.place()` y las creaciones dinámicas de los 29 scripts del juego; el antiguo uso del retrato con `SubViewport` se corrigió. También se confrontaron los clips `alert`, `surprise` y `relief` con los nombres presentes en `art/source/build_assets.py`, sin confundir esa correspondencia textual con una prueba de importación GLB.

**Pendiente y riesgo:** la selección de materiales está definida en el código, pero su validez visual solo se confirma con las texturas de los GLB ya importados. Las baterías de pruebas y el parser Godot 4.4.1 no se ejecutaron; falta renderizar capturas, comprobar animaciones y medir FPS y temperatura en Android. El modelo fuente Scottish Terrier actualizado sigue sin reexportarse.

## Etapa 6 — cierre de campaña, orientación y avisos voluntarios

Rama `feat/v018-stage6-campaign-closure-no-build`, basada directamente en la
etapa 5N. Conserva la cadena completa de cambios anteriores sin modificar
`main`, activar workflows ni generar APK.

- Se cerraron los requisitos de avance: operarios y tres mejoras locales antes
  de salir de cada pueblo. Wivori usa su equipo base y mejoras comerciales;
  mochila, velocidad y ayudantes extra son ampliaciones opcionales.
- Se añadió **Puerto Aurora**, sexto escenario: cuatro proyectos, astillero,
  casa de navegación, barco mercante y tres expediciones elegibles. La meta
  global requiere completar las tres rutas diferentes, no repetir una sola.
- Se suprimió la apertura automática de las tarjetas, incluso por construir
  o llegar a una isla. Las novedades se leen por decisión del jugador en el mapa.
- Se rediseñó el tablero de pedidos con SVG propio y espacio fijo para título,
  producto y progreso; se corrigió la medida de carteles multilínea.
- El HUD usa destino y avance actuales en lugar de quedarse en «15/15»;
  el mapa distingue pendientes y separa la flota en su propia pestaña.
- La guía considera falta de dinero, almacén, fabricación, contratación,
  ingredientes y carga de frutas al viajar. Las compras de talleres exigen
  acudir al lugar. Se conserva el control manual.
- El guardado v8 añade los datos de Aurora y su transacción en viaje; conserva
  el acceso a destinos de partidas anteriores. El pago llega a la caja física.
- Revisiones ejecutadas exclusivamente sobre fuente: gramática externa,
  referencias literales, SVG, grafo de 24 proyectos y 11 recetas, pagos de
  expediciones comparados con venta directa, diferencias y ascendencia Git.
- Se prepararon y actualizaron escenarios de regresión **sin ejecutarlos**.
  No se ha evaluado en pantalla la calidad artística ni se ha probado Android.

El detalle de requisitos, economía y verificaciones que faltan está en
[`CAMPANA-SECUENCIAL.md`](CAMPANA-SECUENCIAL.md). La validación con el motor,
exportación del personaje y alineación del paquete de publicación permanecen
pendientes; no se presentan como trabajo ya realizado.

## Etapa 7 — modelo exportado y revisión de ojos

Rama `feat/v018-stage7-hero-export-no-build`, continuación de la etapa 6.
Se utilizó Blender para crear y revisar el recurso, conservando la instrucción
de no ejecutar Godot, pruebas de juego, workflows ni APK.

- Exportado `hero.glb` y guardada su fuente editable actualizada.
- Corregido el defecto observado de perfil: iris y pupila eran piezas
  superpuestas que sobresalían. Ahora se pintan en un solo ojo, con cuenca
  esculpida en la cabeza y borde del color del pelaje.
- Orejas más cortas y gris carbón ajustado. Sin nombre de protagonista nuevo
  ni cambios de modelos de los NPC.
- Atlas incrustado y textura de importación sincronizados; no se mezcla una
  malla nueva con una textura de cara antigua.
- Inspección del GLB: 17 huesos, 14 clips, tres superficies, 54 140 triángulos,
  pesos normalizados y archivo de 3 221 704 bytes.
- Ocho vistas renderizadas e inspeccionadas en Blender: frente, tres cuartos,
  perfil, espalda, carrera, carga, cosecha y parpadeo. No acreditan fluidez,
  rendimiento ni calidad de presentación dentro de Godot.
- Generador, inspector de archivo y revisión de autoría reproducibles incluidos.
  El AO de 0.16 queda identificado como histórico; el GLB usa su atlas final.

Pendientes: reimportación y transiciones en Godot, contacto de patas, carga
visible, recorrido entre escenarios, balance, colisiones y pruebas Android.
Sigue pendiente preparar versión y publicación después de esas verificaciones.

## Regla de entrega
Para cada etapa registrar: archivos modificados, capturas o video real,
fallos reproducidos y corregidos, pruebas ejecutadas, APK reproducible y
limitaciones pendientes. Si la calidad aún es inferior al objetivo,
indicarlo expresamente, nunca presentar una escena técnica como arte final.
