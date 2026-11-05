# Changelog

## 1.0.0 — noviembre 2026
Primera versión pública.
- Sin instalador: dos archivos, `ping-tray.ps1` y `ping-tray.bat`, en la carpeta que quieras. Licencia GPL-3.0 en `LICENSE`.
- `ping-tray.bat` arranca el script sin ventana.
- También con una sola línea de PowerShell, que descarga los dos archivos de la última release a `%LOCALAPPDATA%\ping-tray` y arranca el `.bat`.
- Menú y mensajes en inglés: **Start with Windows** (con marca; ping-tray se abre solo al iniciar sesión, en el Administrador de tareas aparece como ping-tray, y la marca del menú respeta si se desactiva desde ahí), **Sound**, **About** y **Exit**.
- **Sound** (apagado la primera vez): un aviso al cortarse la conexión (rojo) y otro al volver. Usa sonidos que trae Windows (`Speech Off` y `Speech Disambiguation`), subidos de volumen en memoria porque vienen grabados muy flojos (ajustable con `$SoundLevel`). Si se activa, se recuerda en `HKCU\Software\ping-tray`; al desactivarlo se borra la clave.
- El menú se abre con clic izquierdo o derecho.
- El ping va en segundo plano: el menú responde al instante aunque la conexión vaya lenta o no haya.
- Una sola instancia: si se lanza otra vez, la segunda se cierra sola.
- Al salir se cierran ordenadamente el temporizador, el ping y el icono.
- Si se pega el script directamente en PowerShell (`irm … | iex`), funciona en esa ventana mientras siga abierta.

## 0.1.0 — octubre 2026
Versión de uso personal, antes de publicar.
- Punto de color en la bandeja: verde, naranja, rojo y gris.
- Ping de 8 bytes cada 3 s a 8.8.8.8; un fallo suelto no cuenta como corte.
- Se relanza sin ventana con `conhost --headless`.
