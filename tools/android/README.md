# Firma de los APK de prueba

`debug.keystore` es una identidad **pública y exclusiva de desarrollo**, con alias
`androiddebugkey` y contraseñas estándar `android`. Se versiona deliberadamente:
las pruebas no dependen de una llave aleatoria de cada runner ni de una caché que
pueda caducar. No es una credencial de producción ni se debe usar para Google Play.

Los próximos APK 0.4.x generados con esta llave podrán actualizarse entre sí sin
desinstalar. Los APK anteriores tenían una firma diferente en cada compilación;
Android puede exigir desinstalar esa versión una última vez y eso borra su guardado.

Para una publicación comercial, crear una llave privada distinta, guardarla fuera
del repositorio y configurar la firma de lanzamiento mediante secretos de CI.
Nunca reemplazar esta llave pública por una llave de lanzamiento privada.

Verificación local:

```sh
keytool -list -keystore tools/android/debug.keystore -storepass android -alias androiddebugkey
```
