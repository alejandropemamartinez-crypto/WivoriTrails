# Campaña secuencial — revisión de fuente, etapa 6

Esta implementación continúa la rama `feat/v018-stage5n-input-modal-qa-no-build`.
No es una versión publicada: no se ejecutaron Godot, pruebas funcionales,
capturas ni compilación Android. Los requisitos siguientes están implementados
en código y necesitan validarse jugando antes de aprobarlos.

## Propósito y avance

La meta es fundar una red comercial: desarrollar seis escenarios, reconstruir
el Faro, completar la industria y realizar las tres rutas distintas de Aurora.
El progreso abre otra actividad; no se limita a subir el precio del mismo puesto.

| Escenario | Decisión principal | Requisito de salida |
|---|---|---|
| Wivori | Atender, contratar y defender el mercado | Nivel 6; equipo base de cuatro ayudantes; caja, huerto, muelle, recaudación y defensas completas; reparar ferry por 900 |
| Villa Miga | Distribuir trigo entre harina, alimento, pan y huevos | Construcciones; cuatro operarios contratados; tres mejoras de cada receta; abastecer la ruta a Nata |
| Puerto Nata | Repartir alimento, vender leche o transformarla | Construcciones; operarios y tres mejoras de leche, queso y carne; abastecer la ruta a Farol |
| Bahía Farol | Combinar suministros de otras islas | Construcciones del puerto y Faro; operario y tres mejoras de provisiones; inaugurar la ruta |
| Distrito Forja | Equilibrar empaques, conservas y kits | Cinco proyectos industriales; tres operarios y todas sus mejoras; ronda de seis contratos mixtos |
| Puerto Aurora | Elegir carga y duración de una expedición | Cuatro proyectos del astillero y completar una expedición de cada una de las tres rutas |

La mochila y velocidad son mejoras personales globales y no bloquean un mapa.
Los ayudantes adicionales al equipo base de cuatro siguen siendo expansión
opcional; no se exige pagar doce contrataciones de precio exponencial antes de
ver la primera granja. Los talleres tienen tres niveles finitos. Un empleado
pagado y después pausado sigue contando como contratado.

Hay **24 proyectos** marítimos (15 históricos, 5 de Forja y 4 de Aurora) y
**11 recetas**. Los quince identificadores y el contador histórico `stage`
conservan su orden para que una partida anterior no pierda edificios.

## Guía y avisos

- Ninguna misión, fila, compra disponible, construcción o llegada abre por sí
  sola una tarjeta que pause el juego.
- Las novedades de destino se consultan voluntariamente desde **Mapa y meta →
  Novedades**. La tarjeta grande solo aparece después de tocar ese control.
- El premio de nivel sigue requiriendo el botón **Continuar** del objetivo.
  No depende de leer novedades ni se entrega dos veces.
- Los avisos de compra disponible se dibujan localmente una sola vez por precio,
  cerca de su caseta, en lugar de otro mensaje sobre la zona de juego.
- El mapa identifica el escenario actual, su finalidad, mejoras pendientes,
  destinos abiertos y siguiente proyecto. La cabecera ya no muestra 15/15
  durante los arcos industrial o naval.
- Si falta dinero, la guía propone cobrar, vender, recoger un lote o cosechar.
  Si falta un ingrediente, guía a su producción y al embarcadero correspondiente.
- Contratar o mejorar un taller requiere acudir a él; señalar nunca hace que
  el protagonista camine solo.

## Tablero de pedidos

El antiguo texto largo «PEDIDO PREMIUM ×2» se sustituyó por un tablero SVG
propio de tamaño fijo, título **PEDIDOS ×2**, producto y cantidad separados.
Incluye estados bloqueado, activo y completado, tipografía Quicksand y fondo
opaco de alto contraste. Los cambios de producto no modifican su escala.
La legibilidad real, oclusiones y tamaño en Android siguen pendientes de render.

Los carteles generales calculan ancho por la línea más larga y alto por número
de líneas; ya no miden un bloque multilineal como una única cadena horizontal.

## Puerto Aurora y expediciones

El sexto mapa tiene embarcadero, astillero, casa de navegación y lanzamiento
de la flota. Su barco mercante es independiente del ferry del protagonista.
La pestaña **Flota** agrupa las rutas sin enterrarlas bajo todo el inventario.

| Ruta | Carga | Tiempo activo | Pago en caja de Aurora |
|---|---|---:|---:|
| Correo de la costa | 3 kits y 6 panes | 90 s | 2 100 |
| Abastecimiento de puertos | 6 conservas, 8 leches y 6 empaques | 150 s | 3 300 |
| Gran travesía comercial | 6 kits, 6 provisiones y 6 quesos | 240 s | 5 600 |

Los tres pagos superan el valor equivalente de vender esos mismos productos
directamente en Aurora. Esto es una comprobación aritmética del diseño,
no una prueba de que el balance sea divertido.

Solo hay un cargamento en viaje. Despachar consume una vez los insumos;
el temporizador avanza mientras se juega o se navega en otros destinos.
Al terminar, el pago queda en la caja física de Aurora y hay que recogerlo.
No se da dinero al iniciar ni por volver a pulsar. El viaje y el estado de
pago se guardan; no se añaden ganancias por tiempo con la aplicación cerrada.
Repetir la ruta corta tres veces no completa las tres rutas distintas.

## Compatibilidad y comprobaciones pendientes

El guardado exterior sigue en v8; se añaden campos de campaña y expediciones.
La lectura conserva los destinos ya abiertos en partidas antiguas, además de
inventario, empleados, mejoras, dinero en caja y carga en tránsito. Los nuevos
requisitos se aplican a futuras aperturas; no retiran un pueblo ganado.
No cambian el paquete Android, la firma ni el nombre que determina `user://`.

Análisis estático efectuado: gramática con gdtoolkit, referencias literales a
recursos, XML de SVG, dependencias de proyectos/recetas y diferencias Git.
Eso no comprueba tipos de Godot, importación GLB, animación, colisiones reales,
FPS, persistencia en un teléfono ni calidad artística.

Se preparó `tests/campaign_flow_tests.gd` y se adaptaron las expectativas
anteriores que exigían popups automáticos. No se ejecutaron. Quedan:

1. Importar y ejecutar en Godot 4.4.1; corregir los fallos reales que aparezcan.
2. Recorrer una partida desde cero y migrar partidas anteriores.
3. Revisar carteles, objetivos, tres pestañas, gestos y navegación a
   720×1280 y 720×1600, con capturas del motor.
4. Exportar y evaluar la escultura actualizada del protagonista: los cambios
   de Blender de las etapas previas todavía no están en `hero.glb`.
5. Medir manejo, FPS, memoria, temperatura y ritmo económico en Android.
6. Alinear versión Android, notas y publicación antes de compilar; la
   discrepancia heredada 0.16.1/0.16.0 no se presenta como un lanzamiento nuevo.

Hasta entonces no corresponde decir «sin bugs», «gráficos profesionales»
ni «juego terminado». Esta entrega cierra el diseño y código de esta etapa;
la aprobación visual y funcional permanece abierta por la modalidad sin ejecución.
