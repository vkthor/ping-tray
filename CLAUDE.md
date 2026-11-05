# ping-tray — instrucciones para Claude Code

Indicador de conectividad en la bandeja de Windows. Un script de PowerShell y un `.bat` que lo arranca.
Autor: VkThor (Víctor Cruz). Licencia: GPL-3.0. Repo público: `vkthor/ping-tray` en GitHub.

Lee `docs/PLAN.md` al empezar: tiene las decisiones tomadas y las fases de trabajo.

## Principios (no negociables)

- **Simple.** Un `.ps1` y un `.bat`. Sin instalador, sin desinstalador, sin automatizaciones. Víctor lo pidió expresamente: no añadir piezas nuevas sin que él lo pida.
- **Todo es PowerShell legible.** Nada de `.exe`, binarios, código ofuscado ni dependencias externas. Que cualquiera pueda leer el script en cinco minutos es el motivo del proyecto.
- **Windows PowerShell 5.1** (el que trae Windows 10/11). Si algo funciona en PowerShell 7 pero no en 5.1, no sirve.
- **Sin administrador.**
- **Se ejecuta siempre una copia LOCAL.** Nada de lanzar un PowerShell oculto que descargue código y lo ejecute: Windows Defender lo bloquea como malware (pasó en la primera publicación de la 1.0.0, que se borró), y no se intenta esquivar. Si alguien pega el script con `irm … | iex`, debe funcionar en esa ventana: nada de `exit` (usar `return`), nada que dependa de `$PSCommandPath` o `$PSScriptRoot` sin comprobarlo (ver PLAN, D1).
- Lo único que toca fuera de su carpeta: el acceso directo `ping-tray.lnk` de la carpeta de Inicio (sólo si se marca «Start with Windows») y la clave `HKCU\Software\ping-tray` (sólo mientras «Sound» está activado). Nada de ficheros de configuración.
- Consumo mínimo de red y CPU. Cualquier función nueva que mande más tráfico tiene que ser opcional.

## Archivos

| Archivo | Qué es |
|---|---|
| `ping-tray.ps1` | El programa. |
| `ping-tray.bat` | Una línea: arranca el script sin ventana con `conhost --headless`. |
| `LICENSE` | Texto oficial de la GPL-3.0. |
| `docs/PLAN.md` | Decisiones y fases. |
| `CHANGELOG.md` | Cambios por versión. |

## Convenciones técnicas

- `.ps1` en **UTF-8 SIN BOM y CRLF**; `.bat` en ASCII con CRLF (ver `.editorconfig` y `.gitattributes`). Con BOM, `irm … | iex` falla (la marca llega como un carácter y rompe la primera línea). Sin BOM, Windows PowerShell 5.1 lee como ANSI, así que **todo lo que no sea comentario tiene que ser ASCII**; las tildes, sólo en comentarios. Comentarios en español con tildes normales (y «sólo» con tilde cuando equivale a «solamente»). Todo lo que se ve en pantalla (menú, mensajes, About) va en **inglés**, decisión de Víctor; así no hacen falta caracteres especiales en los textos.
- **Comentarios como en botikor:** cabecera con copyright y SPDX GPL-3.0, bloques separados por `# ====` con título en mayúsculas (CONFIGURACION, MENU, PING…), y un comentario antes de cada trozo que explique qué hace y, sobre todo, por qué, para alguien que no programa. Al cambiar código, actualizar sus comentarios.
- La versión vive en `$Version` en `ping-tray.ps1` (fuente de verdad) y se anota en `CHANGELOG.md`.
- Antes de cada entrega:
  - `Invoke-ScriptAnalyzer -Path . -Recurse` sin errores (módulo PSScriptAnalyzer, ya instalado).
  - Comprobar que el `.ps1` parsea: `[System.Management.Automation.Language.Parser]::ParseFile(...)`.
  - Comprobar que no hay BOM y que no hay caracteres no ASCII fuera de los comentarios (con los tokens del mismo `ParseFile`).
  - Si se ha tocado el arranque: probar también `irm … | iex` con un servidor local que sirva el script como `text/plain; charset=utf-8`, y mirar `Get-MpThreatDetection` por si Defender ha bloqueado algo.
- `gh` está instalado y conectado a la cuenta `vkthor`. Si la terminal no lo encuentra, usar `C:\Program Files\GitHub CLI\gh.exe`.

## Cómo trabajamos

- Víctor no es programador de oficio: explicaciones en español, sencillas y directas. Él decide.
- Modo plan para cualquier cambio no trivial.
- Las correcciones se aplican sin comentar el proceso.
- Víctor prueba en su Surface (Windows 11 Pro) y pasa capturas. Si algo falla, pedir la salida antes de suponer.
- Cada cambio: actualizar CHANGELOG y pasar las comprobaciones de arriba.
- **La versión sólo se sube cuando Víctor lo pide.** Mientras no lo diga, los cambios van dentro de la versión actual (y, si ya estaba publicada, se rehace esa release).
- **Nada se sube a GitHub** (crear repo, push, release) sin el visto bueno explícito de Víctor en el chat.
