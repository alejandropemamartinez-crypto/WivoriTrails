# Wivori Trails 0.19.1 · renovación visual del mercado

Incluye la [renovación visual de 0.19.0](release-v0.19.0.md): arquitectura
costera, edificios con materiales nuevos, cámara ortográfica, recorte de tejados
que tapan al personaje, interfaz compacta y avisos de robo sin duplicados.

La revisión final de capturas detectó que la comprobación de distancia volvía a
mostrar el cartel de pedidos antes de desbloquearlo. Ahora solo aparece desde
el nivel 4 y cerca del jugador. Se comprueban los estados bloqueado, desbloqueado,
lejos y regreso con la misma orden para evitar que reaparezca el error.

Conserva los seis mapas, el control manual, la automatización mediante
trabajadores y las partidas v8. APK ARM64, versión 0.19.1, código 22 y certificado
de prueba estable. Las capturas proceden del juego ejecutado en Godot.

Compilación y pruebas automáticas verificadas; no se ha probado en un teléfono
físico ni medido su rendimiento en Android.
