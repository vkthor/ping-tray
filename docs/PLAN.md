# ping-tray — plan

## Decisiones tomadas

**D0. Simple ante todo.** Un `.ps1` y un `.bat` que lo arranca. Nada de instalador, desinstalador, releases con hash ni automatización. Si una idea necesita más archivos o más pasos para el usuario, probablemente no vale la pena.

**D1. Lo recomendado es ejecutar la copia local; arrancar desde internet es una opción a mano, nunca automática.** El acceso directo de Inicio apunta siempre a un fichero local. Nada de accesos directos tipo `irm https://… | iex`:
1. Es un indicador de conexión: si arranca desde internet, no arranca cuando no hay internet, que es justo cuando hace falta.
2. Lo que se ejecuta no tiene por qué ser lo que el usuario leyó en GitHub: si el repo cambia o la cuenta se compromete, todos los PCs ejecutan el código nuevo sin enterarse.
3. Los antivirus marcan cada vez más los accesos directos con `iex (irm …)`.

Víctor quiso además poder arrancarlo sin descargar nada (`irm … | iex` con relanzamiento oculto). Se probó en la primera publicación de la 1.0.0 y **Windows Defender lo bloquea** (VirTool:PowerShell/MaleficAms): un PowerShell oculto que descarga código y lo ejecuta es una técnica de malware. No se intenta esquivar al antivirus. Esa release se borró y la 1.0.0 se volvió a publicar así:
- La opción B del README es una línea que descarga los dos archivos de la última release a `%LOCALAPPDATA%\ping-tray` y arranca el `.bat`. Es una copia local normal (Start with Windows funciona). Probada: Defender no dice nada.
- Si alguien pega el script con `irm … | iex`, funciona en esa misma ventana mientras siga abierta; no se relanza.

**D2. Un solo archivo de programa.** La configuración son unas pocas variables al principio del script; se cambian con el Bloc de notas. La única preferencia que se recuerda (Sound) va en el registro del usuario, `HKCU\Software\ping-tray`, no en un fichero; sin el sonido activado, la clave no existe.

**D3. Sin instalación.** El usuario pone los dos archivos en la carpeta que quiera (o usa la línea de la opción B). «Start with Windows» en el menú crea o borra el acceso directo de la carpeta de arranque automático (Startup); en el README no se habla de carpetas, sólo de «se abre solo al iniciar sesión». Para quitarlo: desmarcar, salir, borrar la carpeta. (Sustituye al instalador por usuario de los primeros borradores.)

**D4. Lanzamiento sin ventana** con `conhost.exe --headless`. Funciona en Windows 11, pero es una opción no documentada y no está comprobada en Windows 10. Si `conhost` no se puede lanzar, el script usa `-WindowStyle Hidden` (parpadeo breve). El README dice «probado en Windows 11».

## Fase 1 — v1.0 publicable (hecha)

1. `$Version = '1.0.0'`. ✔
2. Instancia única con Mutex. ✔
3. Cerrar ordenadamente al salir (timer, ping, icono, mutex). ✔ Los iconos de `GetHicon` no se liberan a mano: son 4 y Windows los libera al cerrar.
4. Menú (en inglés): Start with Windows / Sound / About / Exit. ✔
5. `ping-tray.bat`. ✔
6. Opción «Sound» en el menú, apagada la primera vez y recordada en el registro (HKCU) si se activa: `Speech Off.wav` al pasar a rojo (se probó `Speech Misrecognition`, pero al ser tan corto se oía flojo) y `Speech Disambiguation.wav` al salir de rojo (de `C:\Windows\Media`). El naranja no suena. Si falta el fichero, no suena. Los dos .wav vienen muy flojos: se suben de volumen en memoria hasta `$SoundLevel` (80 %). ✔
7. El menú se abre con los dos botones. El ping va con `SendAsync` para no bloquear el menú (con `Send` se quedaba parado hasta 1,5 s esperando la respuesta). ✔
7b. «Start with Windows» apunta a `ping-tray.bat` (en el Administrador de tareas sale como ping-tray, no como «Console Window Host») y su marca tiene en cuenta si se desactivó desde el Administrador de tareas (clave `StartupApproved\StartupFolder`, formato no documentado). ✔
8. Opción B: una línea que descarga los dos archivos y arranca el `.bat`; pegado con `irm … | iex`, funciona en la ventana (ver D1). ✔
9. `LICENSE` con el texto oficial de la GPL-3.0. ✔
10. Revisión completa del script. ✔
11. Probado por Víctor en la Surface (salvo la opción B definitiva, que se prueba al publicar). ✔

## Fase 2 — publicación en GitHub (sólo con el visto bueno de Víctor)

1. Repo público `vkthor/ping-tray`. ✔
2. Release `v1.0.0` con `ping-tray.ps1` y `ping-tray.bat` (la opción B descarga de `releases/latest/download/`). Publicada dos veces: la primera se borró por lo de Defender (ver D1). ✔
3. Probar la opción B del README contra GitHub de verdad. ✔
4. Capturas del punto en `docs/img/`, recortadas para que no se vea ningún otro icono de la bandeja. README bilingüe: `README.md` en inglés y `README.es.md` en español, como en redes-movil-adb. ✔
5. Documentación: los avisos de Windows al abrir un `.bat` descargado y los de los antivirus ya están en el README (Preguntas); repasarlos en el tutorial.

## Fase 3 — opcional, cuando Víctor lo pida

- Segundo destino (p. ej. `1.1.1.1`) cuando falla el primero, para distinguir «Google no responde» de «no hay red».
- Notificación de Windows al recuperar la conexión, con cuánto ha durado el corte. Desactivada por defecto.
- Registro opcional de cortes en un CSV.
- Textos en español e inglés según el idioma de Windows (`$PSUICulture`).
