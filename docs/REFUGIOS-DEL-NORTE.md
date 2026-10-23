# Refugios del Norte

La dirección de 0.21.0 cambia el inicio a gestión directa de una ciudad nevada.
Una sola meta organiza el crecimiento: elevar el corazón térmico, alojar y
asignar habitantes y preparar la ruta al siguiente refugio.

## Referencia y decisiones

Se revisaron la [ficha oficial de Whiteout Survival](https://apps.apple.com/us/app/whiteout-survival/id6443575749)
y la [guía editorial de edificios de Google Play](https://play.google.com/store/apps/editorial?hl=en_US&id=mc_games_editorialevergreen_all_about_buildings_in_whiteout_survival_postinstall_fcp).
Consulta: 22 de octubre de 2026.

| Patrón de la referencia | Implementación propia |
| --- | --- |
| Un edificio central organiza el desarrollo | Corazón térmico de cobre con ocho niveles y requisitos visibles |
| Habitantes asignados a puestos de producción | Personas limitadas por hogares; controles − y + para cambiar trabajos |
| Frío, alimentos y cuidados mantienen el pueblo | Carbón, calor, bienestar, invernadero y enfermería |
| Una mejora abre la siguiente posibilidad | Guía que resuelve requisitos y señala el productor del recurso faltante |
| Actividad del asentamiento y exploración | NPC de especies distintas, carga visible, tres viajes de exploradores |
| Desarrollo prolongado de la ciudad | Seis refugios secuenciales con especializaciones y producción compartida |

El arte es propio: edificios nevados editables en GDScript, nieve y materiales
procedurales, iconos vectoriales y los personajes originales del repositorio.
No se incorporaron archivos del cliente, textos de misiones, logotipos, héroes,
pantallas o paquetes de Whiteout Survival. Es una campaña para un jugador;
no implementa alianzas, chat, PvP, servidores ni compras.

## Economía y recuperación

- La madera, comida, carbón y metal comparten almacén entre los refugios abiertos.
- El aserradero inicial no cuesta recursos y siempre permite recuperar la economía.
- La producción necesita habitantes asignados. Los hogares limitan la población.
- Una obra descuenta el costo una sola vez. No puede iniciarse otra hasta terminar.
- La fundición reserva al menos 120 de madera y 70 de carbón antes de convertir excedentes.
- La baja comida o el frío reducen el bienestar y la productividad; no eliminan la población.
- Una ventisca dura 32 segundos. Se acredita su hito con al menos 25 segundos de calor suficiente.
- Un robo exige señales manuales. Mejorar la guardia reduce su número; nunca mueve al protagonista.
- Las rutas duran 35, 50 y 65 segundos; en Costa Cristal, 28, 40 y 52.
- El progreso fuera de pantalla está limitado a dos horas. Las expediciones y obras terminan
  usando la misma lógica de transacciones; no se aplican robos o ventiscas mientras la app está cerrada.

## Guardado y controles

`wivori_refuge_save.json` conserva la gestión nevada. El archivo anterior
`wivori_trails_save.json` continúa perteneciendo al archipiélago y no se migra ni
sobrescribe al guardar el refugio. Ambos utilizan la escritura atómica y respaldo
del guardado v8. Se mantiene el paquete y certificado Android de pruebas.

El inicio usa la cámara de gestión. Se puede desplazar con un dedo y acercar con
dos. El menú permite pasear con joystick, WASD o flechas; elegir una tarea solo
abre su edificio o panel. Las obras actualizan las cifras sin sustituir un botón
mientras un dedo lo mantiene pulsado. Las noticias nunca abren un panel solas.

## Validación y límites

Las suites prueban la economía desde el kit inicial hasta los seis refugios y
las tres expediciones, sin asignar recursos o niveles artificiales. Otras pruebas
preparan estados para verificar daños de guardado, doble cobro, pausa de Android,
tiempos fuera de pantalla, reservas de materiales y requisitos de viaje.

La interfaz se prueba con eventos táctiles reales del motor en 720×1280 y
720×1600. Las capturas visuales usan estados preparados y muestran la escena
que se exporta, no ilustraciones de una futura versión. La revisión por software
de escritorio no mide FPS, batería, temperatura o sensación de uso en Android
físico. La simulación tampoco demuestra retención o diversión de personas reales.
