# Arte de Wivori Trails 0.14

Se creó específicamente para este proyecto. No se utilizaron personajes,
edificios, texturas ni recursos de Township/Playrix ni de otros juegos.

| Recursos | Fuente editable | Uso |
| --- | --- | --- |
| Terrier gris atigrado | `source/terrier.blend` | Protagonista y vecinos caninos |
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
