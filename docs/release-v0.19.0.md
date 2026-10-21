# Wivori Trails 0.19.0 · mercado costero

El mercado y las fábricas usaban casas intercambiables, carteles muy grandes y
una cámara que agrandaba los tejados del primer plano. Esta versión incorpora
arquitectura completa con puestos abiertos, panaderías con horno y mostrador,
establos, invernaderos, molinos y naves industriales de producción visible.

- Cámara ortográfica con zoom y vista de construcción. Los edificios cercanos
  recortan su parte superior cuando ocultarían al protagonista.
- Tejados curvos, molduras, carpintería, escaparates y jardines agrupados en pocas
  superficies por edificio. El nuevo atlas aporta madera, estuco, cerámica,
  piedra, hojas y tierra; incluye mipmaps para reducir el parpadeo a distancia.
- Costa y relieve al fondo de Wivori, arbolado y bordes floridos; se mantienen
  corredores transitables y las posiciones de los puestos y proyectos.
- Monedas y mochila en tarjetas compactas, misión más breve, controles inferiores
  más pequeños y señalización que aparece cerca sin cubrir al personaje.
- Los robos usan una sola mensajera; se eliminan los mensajes inferiores que
  repetían sus avisos de llegada, robo y recuperación. El aviso no bloquea moverse.
- Los pedidos ×2 muestran un cartel más pequeño desde su desbloqueo en nivel 4.
- El catálogo muestra capturas de los modelos que se construyen actualmente.

El protagonista sigue sin nombre y bajo control manual. La automatización sigue
perteneciendo a los trabajadores contratados. Se mantienen los seis mapas,
la campaña, las defensas, los pedidos, los viajes y el guardado v8.

## Verificación

Se revisan capturas del motor en retrato, pruebas táctiles con gráficos activos,
cosecha/entrega/cobro/contratación, defensa, navegación y viajes entre pueblos.
La regresión `terrain_surface_tests.gd` compara la altura visible del terreno
con los caminos y la altura que usa el personaje para apoyar los pies.

Las capturas preparadas se reproducen con:

```sh
godot --path . --audio-driver Dummy --resolution 720x1600 \
  --script res://tools/capture_coastal.gd -- /tmp/coastal-captures
```

Las mediciones del renderizador Linux de software no son FPS de Android. Hace
falta una prueba en teléfono para valorar rendimiento, temperatura y consumo.

APK ARM64, versión 0.19.0, código 21, paquete
`sv.apenalegaltech.wivoritrails`, con el certificado de prueba estable del proyecto.
La instalación sobre la versión anterior conserva el directorio de guardado.
