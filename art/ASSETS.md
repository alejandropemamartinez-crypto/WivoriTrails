# Arte de Wivori Trails

Se creó específicamente para este proyecto. No se utilizaron personajes,
edificios, texturas ni recursos de Township/Playrix ni de otros juegos.

| Recursos | Fuente editable | Uso |
| --- | --- | --- |
| Perrito aventurero sin nombre | `source/hero.blend` | Protagonista exclusivo |
| Zorro, cerdo y pato | `source/{fox,pig,duck}.blend` | Vecinos y trabajadores |
| Establo, gallinero, corral y cercas | `source/farm_*.blend` | Arquitectura rural y animales |
| Conejo | `source/rabbit.blend` | Ayudantes, recaudador y mensajera |
| Mapache | `source/raccoon.blend` | Incursiones y mercancía robada |
| 9 edificios | `source/{house,cafe,depot,bakery,greenhouse,workshop,park,watchtower,mill}.blend` | Bonificaciones económicas del pueblo |
| 10 puestos | `source/booth_*.blend` | Contratación, herramientas y defensas |
| Mercado y carro premium | `source/{market,premium}.blend` | Venta y pedidos |
| Cajas, tesorería, bolsa y monedas | `source/{register,treasury,money_bag,coin}.blend` | Recaudación física |
| Árbol y cuatro productos | `source/{tree,produce_*}.blend` | Huertos y transporte |
| Atlas de personajes | `source/textures/*.png` | Color y sombras de contacto |
| Iconos y placas | `../assets/ui/` y `../scripts/world.gd` | Interfaz y carteles |

Cada personaje tiene un esqueleto de 17 huesos con pesos de deformación y los
clips `idle`, `walk`, `run`, `turn`, `harvest`, `carry`, `deliver`, `collect`,
`celebrate`, `surprise`, `intercept`, `build`, `alert` y `relief`.

## Reproducir y editar

Blender 4.x, con su exportador glTF y Cycles CPU. El proyecto se generó y revisó
con Blender 4.0.2. El generador incluye topología, colores, pesos, acciones,
construcción arquitectónica, UV, texturas y exportación; no requiere complementos
comerciales. Las texturas y la geometría se comprueban antes de exportar.

```sh
blender --background --factory-startup --python art/source/build_assets.py
```

Para una parte concreta, agregá `-- characters`, `-- buildings`, `-- garden` o
`-- props`. Los archivos de ejecución son GLB estándar; sus materiales usan PBR
sin depender de nodos procedurales exclusivos de Blender. Se agrupan las mallas
estáticas y las superficies de cada personaje para evitar un objeto de dibujo
por teja o accesorio. Los originales conservan esqueleto, UV, materiales y clips.

## Licencias

- **Arte original del proyecto:** `LICENSE.txt`. Reservado al titular de Wivori
  Trails; puede usarlo, editarlo y distribuirlo en su juego, incluido uso comercial.
  Este archivo no concede a terceros una licencia pública sobre ese arte.
- **Quicksand Bold / Medium:** The Quicksand Project Authors (2011), SIL Open
  Font License 1.1. Fuente: <https://fonts.google.com/specimen/Quicksand/>.
  Se conservan los binarios sin modificar y el aviso completo en
  `assets/fonts/OFL-Quicksand.txt`. Distribución utilizada: paquete Ubuntu
  `fonts-quicksand` 0.2016-2.1. La licencia permite incorporar la fuente al juego.
- Las herramientas Blender y Godot no se redistribuyen dentro de los modelos.
  No se aplica su licencia de programa a los recursos originales generados.

Las capturas son renderizados reales de Godot de una partida preparada para
revisión. Los modelos no son reconstrucciones de ilustraciones ni imágenes
conceptuales presentadas como un juego funcionando.

## Nuevos originales de 0.14

Los .blend de Scottie, compotas, meriendas, cestas, banco y carro de flores son
las fuentes editables autoritativas de esta revisión. Se reexportan sin reconstruir
el esculpido mediante `art/source/export_authored.py`. El generador histórico
`build_assets.py` sigue disponible para los demás modelos. Los nuevos recursos
se rigen por la misma licencia original del proyecto.

## Nuevo protagonista y acabado 0.16

`build_hero.py` reconstruye únicamente el protagonista sin nombre, con su rostro
continuo nuevo, detalles anclados a la piel, ropa, esqueleto, 14 clips y atlas
original de 1024 px. `build_farm_finish.py` genera las tres fachadas agrícolas
y las cercas de madera abiertas. Los shaders de agua, suelo y contacto son
originales del proyecto y funcionan con el renderizador Compatibility.
Los modelos antiguos se conservan como fuentes históricas; el juego carga
`hero.glb` exclusivamente para el jugador.

## Arquitectura costera de 0.19.0

`scripts/coastal_building.gd` es la fuente editable de la arquitectura actual.
Construye y comparte mallas con bordes biselados, tejados curvos, ventanas,
carpintería, puestos abiertos y naves industriales. `scripts/coastal_scenery.gd`
agrupa jardines y muros; `scripts/coastal_surface.gdshader` aplica el acabado.
Los GLB anteriores se conservan como originales históricos y para recursos que
siguen utilizándose, incluidos personajes, animales, productos y mobiliario.

`assets/textures/coastal_atlas.png` es un atlas nuevo generado con IA para este
proyecto, con seis materiales en una cuadrícula 3 × 2: madera, estuco, cerámica,
piedra, hojas y tierra. La geometría, UV, iluminación, cámara e interacción son
del juego ejecutándose en Godot. La imagen conceptual de referencia no se usa
como fondo que sustituya al escenario jugable.

`tools/render_thumbnails.gd` vuelve a crear las nueve imágenes del catálogo a
partir de los edificios actuales, con fondo transparente. No necesita Blender.
Las fachadas mecánicas conservan sus animaciones y las ventanas duplicadas para
los edificios históricos se ocultan al integrarlas en la arquitectura nueva.

## Etapa 7: exportación e inspección del protagonista

El GLB ya corresponde a la escultura actual: cuencas en la cabeza, párpados del
color del pelaje, ojos de una sola superficie con iris y pupila pintados y orejas
más cortas. Se conservan 17 huesos, 14 clips, tres superficies y el nombre del
recurso. El protagonista sigue sin nombre; los NPC no cambian.

Se importó y revisó el GLB en Blender 4.0.2: frente, tres cuartos, perfil,
espalda, carrera, carga, cosecha y parpadeo. Son vistas de autoría, no capturas
del juego. Los registros están en `source/hero.export.json` y `source/hero.review.json`.

El archivo ocupa 3 221 704 bytes y contiene 54 140 triángulos. Esto no acredita
FPS en Android. `source/validate_hero_export.py` inspecciona el archivo y sincroniza
el atlas incrustado con `assets/models/hero_hero_albedo.png`.
El atlas de color incorpora la oclusión ya horneada; el AO independiente de
0.16 se conserva como `textures/hero_contact_shadows_v016.png`, fuente histórica
que no utiliza el GLB nuevo. El generador vuelve a producir el AO intermedio
si se reconstruye el personaje.

```sh
blender --background --factory-startup --python art/source/build_hero.py
python3 art/source/validate_hero_export.py
blender --background --factory-startup --python art/source/review_hero.py -- /tmp/hero-review
```

Quedan pendientes la importación Godot, las transiciones y el contacto de patas
dentro del juego, la carga visible y las mediciones en Android. No se ejecutó
Godot ni se compiló un APK en esta etapa.
