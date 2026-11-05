# ping-tray - indicador de conexión en la bandeja de Windows.
# https://github.com/vkthor/ping-tray
#
# Copyright (C) 2026 Víctor Cruz (VkThor)
# SPDX-License-Identifier: GPL-3.0-or-later
# Este programa es software libre: puedes redistribuirlo y modificarlo bajo
# los términos de la Licencia Pública General GNU (GPL) versión 3 o
# posterior. Se distribuye SIN NINGUNA GARANTÍA. Ver el fichero LICENSE.
#
# Pone un punto de color en la bandeja del sistema y cada pocos segundos
# hace ping a un servidor de internet para saber si hay conexión:
#   verde = OK | naranja = lento o un ping perdido suelto
#   rojo  = sin conexión | gris = arrancando
# Clic en el punto (izquierdo o derecho): Start with Windows / Sound / About / Exit.
# Se arranca con doble clic en ping-tray.bat (en esta misma carpeta).
# Requiere Windows PowerShell 5.1 (el que trae Windows). Sin administrador.
#
# Idioma: los comentarios van en español; lo que se ve en pantalla (menú,
# mensajes, "About"), en inglés, sin caracteres especiales.
# Codificación: UTF-8 SIN BOM (la marca invisible que algunos editores ponen
# al principio). Con BOM, "irm ... | iex" falla: la marca llega como un
# carácter más y rompe la primera línea. Sin BOM, Windows PowerShell 5.1 lee
# mal las tildes de los comentarios, pero da igual: todo lo que no es un
# comentario va en ASCII (letras inglesas, sin tildes).

# -Hidden: lo pasan ping-tray.bat, el acceso directo de "Start with Windows"
# y el relanzamiento para decir "ya estoy arrancado sin ventana, no te
# relances" (ver ARRANQUE).
param([switch]$Hidden)

# VERSIÓN: formato X.Y.Z. Se muestra en "About" y se anota en CHANGELOG.md.
$Version = '1.0.0'
# Página del proyecto, para "About".
$RepoUrl = 'https://github.com/vkthor/ping-tray'

# ============================================================
# CONFIGURACIÓN
#
# Lo único que tiene sentido cambiar. Edita con el Bloc de notas, guarda, y
# sal y vuelve a arrancar el punto para que se aplique.

# A quién se hace ping. 8.8.8.8 es el DNS de Google; 1.1.1.1, el de
# Cloudflare. Los dos responden desde casi cualquier red.
$Target   = '8.8.8.8'
# Milisegundos entre un ping y el siguiente. Menos = se entera antes de un
# corte, pero gasta más datos (con 3000 son unos 100 KB por hora).
$Interval = 3000
# Milisegundos que se espera la respuesta antes de darla por perdida.
# Debe ser menor que $Interval.
$Timeout  = 1500
# A partir de estos milisegundos de respuesta, el punto se pone naranja.
$SlowMs   = 400

# Sonidos para la opción "Sound" del menú (ver SONIDO). Son los del antiguo
# reconocimiento de voz de Windows: vienen con Windows y casi nadie los oye,
# así que no se confunden con los avisos normales del sistema. Se puede
# poner cualquier otro .wav de C:\Windows\Media.
$SoundDownFile = Join-Path $env:SystemRoot 'Media\Speech Off.wav'              # al cortarse
$SoundUpFile   = Join-Path $env:SystemRoot 'Media\Speech Disambiguation.wav'   # al volver
# Volumen de los sonidos, de 1 a 100. Esos dos ficheros vienen grabados muy
# flojos (uno al 16% y otro al 3% del máximo), así que ping-tray los sube
# hasta este nivel. 100 = lo más fuerte posible sin que el sonido se
# distorsione. Va sobre el volumen de Windows: no lo cambia.
$SoundLevel = 80

# ============================================================
# ARRANQUE SIN VENTANA
#
# Un script de PowerShell abre siempre una ventana de consola. Para que no
# se vea, se arranca a través de "conhost.exe --headless", que crea la
# consola sin mostrarla. Es una opción de Windows 11 que Microsoft no
# documenta; si conhost no se puede lanzar, se usa -WindowStyle Hidden, que
# esconde la ventana pero deja ver un parpadeo.
#
# Esta misma orden la usan el relanzamiento de abajo y el acceso directo de
# "Start with Windows" (ver MENÚ). ping-tray.bat lleva la misma, escrita a mano.
# -ExecutionPolicy Bypass: Windows bloquea por defecto los scripts .ps1. Esto
# lo permite sólo para este, sin cambiar la configuración del sistema.

$Conhost = Join-Path $env:SystemRoot 'System32\conhost.exe'
$PsExe   = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$PsArgs  = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Hidden"

# Si alguien pega el script directamente en PowerShell ("irm ... | iex"), no
# hay fichero: $PSCommandPath está vacío y no hay nada que relanzar sin
# ventana. En ese caso el punto funciona en esa misma ventana, mientras siga
# abierta, y "Start with Windows" no está disponible (no hay fichero al que
# apuntar). No se intenta lanzar una copia oculta que descargue el script
# otra vez: Windows Defender lo bloquea, con razón, porque es justo lo que
# hace mucho malware.
$FromWeb = -not $PSCommandPath

# Si se ha lanzado desde un fichero sin -Hidden (por ejemplo, clic derecho >
# "Ejecutar con PowerShell"), hay una ventana visible: se lanza una copia
# sin ventana y esta termina.
# Se usa "return" y no "exit": con "irm ... | iex", "exit" cerraría la
# ventana de PowerShell de la persona.
if (-not $Hidden -and -not $FromWeb) {
    try   { Start-Process $Conhost -ArgumentList "--headless `"$PsExe`" $PsArgs" -ErrorAction Stop }
    catch { Start-Process $PsExe -ArgumentList $PsArgs -WindowStyle Hidden }
    return
}

# ============================================================
# UN SOLO PUNTO
#
# Si ya hay un ping-tray en marcha, este se cierra sin hacer nada. Para
# saberlo se usa un "mutex": una marca con nombre que Windows guarda
# mientras el programa que la creó siga abierto. Si al crearla ya existía,
# es que hay otro. "Local\" = una por sesión de Windows (cada usuario
# conectado tiene su propio punto). Windows la borra sola si el programa se
# cierra de golpe.

$isFirst = $false
$mutex = New-Object System.Threading.Mutex($true, 'Local\ping-tray', [ref]$isFirst)
if (-not $isFirst) {
    $mutex.Dispose()
    if ($FromWeb) { Write-Host 'ping-tray is already running in the system tray.' }
    return
}
# Pegado en PowerShell: se avisa de que la ventana tiene que seguir abierta.
if ($FromWeb) {
    Write-Host 'ping-tray is running in the system tray.'
    Write-Host 'Keep this window open (you can minimize it). Closing it closes ping-tray.'
    Write-Host "To start it without a window, download it: $RepoUrl"
}

# ============================================================
# ICONOS
#
# Windows Forms es la parte de .NET (incluida en Windows) que permite poner
# iconos en la bandeja y mostrar menús. System.Drawing sirve para dibujar.
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# Dibuja un círculo del color indicado en una imagen de 16x16 (el tamaño de
# los iconos de la bandeja) y lo convierte en icono. No se usan ficheros
# .ico para que todo el programa esté en este único archivo.
# Nota: GetHicon reserva un icono en Windows que no se libera a mano; son
# sólo 4 y Windows los libera al cerrar el programa.
function New-DotIcon([System.Drawing.Color]$c) {
    $bmp = New-Object System.Drawing.Bitmap 16, 16
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'     # bordes suaves
    $g.Clear([System.Drawing.Color]::Transparent)
    $b = New-Object System.Drawing.SolidBrush $c
    $g.FillEllipse($b, 2, 2, 12, 12)   # círculo de 12 px con 2 px de margen
    $b.Dispose(); $g.Dispose()
    [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
}

# Los cuatro estados se dibujan una vez al arrancar y luego sólo se cambia
# cuál se muestra.
$icons = @{
    ok   = New-DotIcon ([System.Drawing.Color]::LimeGreen)
    slow = New-DotIcon ([System.Drawing.Color]::Orange)
    down = New-DotIcon ([System.Drawing.Color]::Red)
    wait = New-DotIcon ([System.Drawing.Color]::Gray)
}

# El punto de la bandeja. Text es el mensaje que sale al pasar el ratón.
$tray = New-Object System.Windows.Forms.NotifyIcon
$tray.Icon = $icons.wait
$tray.Text = 'Checking...'
$tray.Visible = $true

# Temporizador que lanza un ping cada $Interval ms (ver PING).
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = $Interval

# ============================================================
# SONIDO
#
# Opcional y apagado la primera vez; se activa en el menú. Suena sólo en
# los cambios importantes: al ponerse rojo (corte de verdad) y al volver a
# verde después de un rojo. Un ping perdido suelto o un momento lento
# (naranja) no suenan, porque en una conexión móvil pasan a menudo.
#
# Si está activado, se recuerda en el registro de Windows, en la parte de
# cada usuario (HKEY_CURRENT_USER, que no necesita administrador): la clave
# HKCU\Software\ping-tray con el valor Sound = 1. Al desactivarlo se borra
# la clave entera, así que con el sonido apagado no queda nada guardado.
$RegKey = 'HKCU:\Software\ping-tray'
#
# Los sonidos se preparan la primera vez que se activa "Sound" (tarda
# menos de un segundo), no al arrancar: si nunca se activa, no se gasta
# nada. Si un fichero no existe (Windows podría quitarlo en alguna versión
# futura), ese sonido se queda en $null y simplemente no suena.

# Lee un .wav, lo sube de volumen hasta $level (1-100) y devuelve un
# reproductor listo para sonar, o $null si el fichero no existe.
# Cómo sube el volumen: un .wav normal (PCM de 16 bits) es una lista de
# números entre -32768 y 32767 que dicen dónde está la membrana del altavoz
# en cada momento; cuanto más grandes, más fuerte suena. Se busca el más
# grande (el "pico") y se multiplican todos por lo mismo, para que el pico
# llegue a $level % del máximo. Sólo se sube, nunca se baja. Si el .wav es
# de otro tipo, se deja tal cual.
function New-LoudSound([string]$path, [int]$level) {
    if (-not (Test-Path $path)) { return $null }
    $bytes = [IO.File]::ReadAllBytes($path)

    # Cabecera del .wav: "RIFF" al principio, formato 1 (PCM) y 16 bits.
    $isPcm16 = $bytes.Length -gt 44 -and
        [Text.Encoding]::ASCII.GetString($bytes, 0, 4) -eq 'RIFF' -and
        [Text.Encoding]::ASCII.GetString($bytes, 12, 4) -eq 'fmt ' -and
        [BitConverter]::ToInt16($bytes, 20) -eq 1 -and
        [BitConverter]::ToInt16($bytes, 34) -eq 16

    if ($isPcm16) {
        # El fichero va por trozos (nombre de 4 letras + tamaño). El sonido
        # en sí está en el trozo "data"; se salta todo lo demás.
        $pos = 12
        $start = 0; $size = 0
        while ($pos + 8 -le $bytes.Length) {
            $name = [Text.Encoding]::ASCII.GetString($bytes, $pos, 4)
            $len  = [BitConverter]::ToInt32($bytes, $pos + 4)
            if ($len -lt 0) { break }   # fichero roto: se deja de buscar
            if ($name -eq 'data') { $start = $pos + 8; $size = [Math]::Min($len, $bytes.Length - $start); break }
            $pos += 8 + $len + ($len % 2)
        }

        if ($size -ge 2) {
            # Se copian los bytes a una lista de números de 16 bits para
            # trabajar con ellos, y al final se devuelven a su sitio.
            $samples = New-Object int16[] ([Math]::Floor($size / 2))
            [Buffer]::BlockCopy($bytes, $start, $samples, 0, $samples.Length * 2)

            $peak = 1
            foreach ($s in $samples) { $a = [Math]::Abs([int]$s); if ($a -gt $peak) { $peak = $a } }

            $gain = ($level / 100) * 32767 / $peak
            if ($gain -gt 1) {
                for ($i = 0; $i -lt $samples.Length; $i++) {
                    $samples[$i] = [int16][Math]::Max(-32768, [Math]::Min(32767, [Math]::Round($samples[$i] * $gain)))
                }
                [Buffer]::BlockCopy($samples, 0, $bytes, $start, $samples.Length * 2)
            }
        }
    }

    # El sonido modificado se reproduce desde la memoria; el fichero
    # original de Windows no se toca.
    $player = New-Object System.Media.SoundPlayer (New-Object IO.MemoryStream (, $bytes))
    $player.Load()
    $player
}

$script:soundDown   = $null
$script:soundUp     = $null
$script:soundsReady = $false

# ============================================================
# MENÚ (clic en el punto)

# Acceso directo en la carpeta de arranque automático del usuario (en
# inglés, "Startup"; no es el menú Inicio): Windows abre todo lo que haya
# ahí cada vez que se inicia sesión. Es lo único que ping-tray crea fuera de
# su carpeta (aparte de la clave de SONIDO), y sólo si se marca
# "Start with Windows". Al desmarcarlo, se borra.
$StartupLnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'ping-tray.lnk'

# Si se desactiva desde el Administrador de tareas ("Aplicaciones de
# arranque"), Windows no borra el acceso directo: apunta en esta clave del
# registro, con el nombre del acceso directo, que no hay que abrirlo. El
# primer byte del valor es par si está activado e impar si está desactivado.
# Microsoft no documenta este formato; si algún día cambia, lo peor que pasa
# es que la marca del menú vuelve a mirar sólo si existe el acceso directo.
$ApprovedKey  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder'
$ApprovedName = Split-Path $StartupLnk -Leaf

# $true si ping-tray va a abrirse al iniciar sesión: existe el acceso
# directo y el Administrador de tareas no lo tiene desactivado.
function Test-StartupEnabled {
    if (-not (Test-Path $StartupLnk)) { return $false }
    $flag = (Get-ItemProperty $ApprovedKey -Name $ApprovedName -ErrorAction SilentlyContinue).$ApprovedName
    return -not ($flag -and ($flag[0] -band 1))
}

$menu = New-Object System.Windows.Forms.ContextMenuStrip

# "Start with Windows": si está activado (ver Test-StartupEnabled), borra el
# acceso directo; si no, lo crea (o lo rehace, si existía pero estaba
# desactivado en el Administrador de tareas), apuntando a la carpeta donde
# esté ahora el script (por eso, si se mueve la carpeta, hay que desmarcarlo
# y volver a marcarlo). En los dos casos borra la anotación del
# Administrador de tareas, para que todo cuadre y no quede nada detrás.
# Apunta a ping-tray.bat y no directamente a conhost.exe: el Administrador
# de tareas, en "Aplicaciones de arranque", enseña el nombre del programa al
# que apunta el acceso directo, y así sale "ping-tray" en vez de "Console
# Window Host", que no dice nada y parece algo de Windows. A cambio, al
# iniciar sesión se ve un instante la ventana del .bat. Si el .bat no está
# junto al script, se usa la orden de ARRANQUE directamente.
# Pegado directamente en PowerShell no hay fichero al que apuntar: la opción
# sale en gris, con una explicación al pasar el ratón (ver ARRANQUE).
$startItem = New-Object System.Windows.Forms.ToolStripMenuItem 'Start with Windows'
if ($FromWeb) {
    $startItem.Enabled = $false
    $startItem.ToolTipText = 'Only available when ping-tray runs from a downloaded copy'
}
$startItem.add_Click({
    # Si Windows no deja crear o borrar el acceso directo, se avisa en vez
    # de dejar que salga un error de los de Windows Forms.
    try {
        $wasEnabled = Test-StartupEnabled
        Remove-ItemProperty $ApprovedKey -Name $ApprovedName -ErrorAction SilentlyContinue
        if ($wasEnabled) {
            Remove-Item $StartupLnk -Force -ErrorAction Stop
        }
        else {
            # WScript.Shell es el componente de Windows que sabe crear accesos directos.
            $lnk = (New-Object -ComObject WScript.Shell).CreateShortcut($StartupLnk)
            $bat = Join-Path $PSScriptRoot 'ping-tray.bat'
            if (Test-Path $bat) {
                $lnk.TargetPath  = $bat
                $lnk.WindowStyle = 7   # minimizada: la ventana del .bat casi no se ve
            }
            else {
                $lnk.TargetPath  = $Conhost
                $lnk.Arguments   = "--headless `"$PsExe`" $PsArgs"
            }
            $lnk.WorkingDirectory = $PSScriptRoot
            $lnk.Description      = 'Connection indicator for the system tray'
            $lnk.Save()
        }
    }
    catch {
        [void][System.Windows.Forms.MessageBox]::Show("Could not change the startup shortcut:`n$($_.Exception.Message)", 'ping-tray', 'OK', 'Warning')
    }
})
[void]$menu.Items.Add($startItem)

# "Sound": con marca. CheckOnClick hace que cada clic ponga o quite la
# marca; el ping mira esa marca para decidir si suena. Cada cambio se
# guarda (o se borra) en el registro, y la primera vez que se marca se
# preparan los sonidos (ver SONIDO). Si no existe ninguno de los dos
# ficheros, la opción sale en gris.
$soundItem = New-Object System.Windows.Forms.ToolStripMenuItem 'Sound'
$soundItem.CheckOnClick = $true
$soundItem.Enabled = (Test-Path $SoundDownFile) -or (Test-Path $SoundUpFile)
$soundItem.add_CheckedChanged({
    if ($soundItem.Checked) {
        if (-not $script:soundsReady) {
            $script:soundDown   = New-LoudSound $SoundDownFile $SoundLevel
            $script:soundUp     = New-LoudSound $SoundUpFile $SoundLevel
            $script:soundsReady = $true
        }
        # Si el registro no se puede escribir, el sonido funciona igual;
        # simplemente no se recordará la próxima vez.
        if (-not (Test-Path $RegKey)) { [void](New-Item $RegKey -ErrorAction SilentlyContinue) }
        Set-ItemProperty $RegKey -Name Sound -Value 1 -Type DWord -ErrorAction SilentlyContinue
    }
    else {
        Remove-Item $RegKey -Recurse -ErrorAction SilentlyContinue
    }
})
[void]$menu.Items.Add($soundItem)
# Si la última vez se dejó activado, se activa ya (esto también prepara
# los sonidos, por el CheckedChanged de arriba).
if ($soundItem.Enabled -and (Get-ItemProperty $RegKey -ErrorAction SilentlyContinue).Sound -eq 1) {
    $soundItem.Checked = $true
}

# "About": versión, autor y la pregunta de si abrir la página del
# proyecto en el navegador.
$aboutItem = $menu.Items.Add('About')
$aboutItem.add_Click({
    $msg = "ping-tray $Version`n`nConnection indicator for the Windows system tray.`nAuthor: VkThor. License: GPL-3.0.`n`n$RepoUrl`n`nOpen the project page?"
    $answer = [System.Windows.Forms.MessageBox]::Show($msg, 'About ping-tray', 'YesNo', 'Information')
    if ($answer -eq 'Yes') { Start-Process $RepoUrl }
})

# Raya separadora y "Exit". Exit sólo detiene el bucle de Windows Forms;
# la limpieza se hace al final del script (ver FINAL).
[void]$menu.Items.Add('-')
$exitItem = $menu.Items.Add('Exit')
$exitItem.add_Click({ [System.Windows.Forms.Application]::Exit() })

# La marca de "Start with Windows" se comprueba cada vez que se abre el
# menú (ver Test-StartupEnabled): así es correcta aunque alguien haya
# borrado el acceso directo a mano o lo haya desactivado en el
# Administrador de tareas.
$menu.add_Opening({ $startItem.Checked = Test-StartupEnabled })
$tray.ContextMenuStrip = $menu

# El clic derecho abre el menú solo. Para que el izquierdo también lo abra,
# se llama a la misma función interna que usa Windows Forms con el derecho
# (ShowContextMenu). No es pública, por eso se busca con "reflection", pero
# así el menú sale en el mismo sitio y se cierra igual al pulsar fuera.
$showMenu = [System.Windows.Forms.NotifyIcon].GetMethod('ShowContextMenu', [Reflection.BindingFlags]'Instance, NonPublic')
$tray.add_MouseUp({
    $e = $args[1]   # datos del aviso (el primero, $args[0], es quien lo manda)
    # Si alguna versión futura de Windows Forms no tuviera esa función,
    # $showMenu estaría vacío: el izquierdo no haría nada y el derecho seguiría funcionando.
    if ($e.Button -eq 'Left' -and $showMenu) { [void]$showMenu.Invoke($tray, $null) }
})

# ============================================================
# PING
#
# En cada tic del temporizador se manda un ping y, cuando llega la
# respuesta, se pone el color. Un ping perdido suelto pone el punto
# naranja, no rojo: en una conexión móvil pasa a menudo sin que la conexión
# se haya caído. Hacen falta dos seguidos para pasar a rojo.
#
# El ping se manda "en segundo plano" (SendAsync): el programa no se queda
# esperando la respuesta, sino que Windows avisa cuando llega (PingCompleted).
# Así el menú responde al instante aunque el ping tarde. Antes se esperaba
# parado, y si el ping tardaba (hasta $Timeout ms sin conexión), el menú
# también tardaba en abrirse.

$pinger = New-Object System.Net.NetworkInformation.Ping
# Datos que viajan en cada ping. 8 bytes es lo mínimo útil; el ping de
# Windows manda 32. Menos datos = menos consumo en conexiones móviles.
$buffer = New-Object byte[] 8
# Pings perdidos seguidos, y hora a la que empezó el corte. "script:" hace
# que se guarden entre un tic y el siguiente.
$script:fails = 0
$script:lastDown = $null
# $true mientras hay un ping esperando respuesta: no se manda otro encima.
$script:busy = $false

# Cada tic manda un ping, salvo que el anterior siga sin contestar.
$timer.add_Tick({
    if ($script:busy) { return }
    $script:busy = $true
    # Si no hay red, SendAsync puede dar error en el acto: se trata igual
    # que un ping perdido.
    try   { $pinger.SendAsync($Target, $Timeout, $buffer, $null) }
    catch { $script:busy = $false; Update-Tray $null }
})

# Cuando llega la respuesta (o se acaba el tiempo de espera), Windows lo
# avisa aquí. $e.Reply es la respuesta; si hubo un error, no hay respuesta.
$pinger.add_PingCompleted({
    $e = $args[1]   # datos del aviso (el primero, $args[0], es quien lo manda)
    $script:busy = $false
    if ($e.Error -or $e.Cancelled) { Update-Tray $null } else { Update-Tray $e.Reply }
})

# Pone el color y el mensaje del punto según la respuesta del ping
# ($null = no ha llegado respuesta).
function Update-Tray($r) {
    $now = Get-Date -Format 'HH:mm:ss'
    if ($r -and $r.Status -eq 'Success') {
        # Ha respondido: verde, o naranja si ha tardado más de $SlowMs.
        # Si veníamos de rojo (2 o más fallos seguidos), suena el de vuelta.
        # Play() no espera a que acabe el sonido: el punto no se queda parado.
        if ($script:fails -ge 2 -and $soundItem.Checked -and $script:soundUp) { $script:soundUp.Play() }
        $script:fails = 0
        $ms = $r.RoundtripTime
        if ($ms -gt $SlowMs) { $tray.Icon = $icons.slow } else { $tray.Icon = $icons.ok }
        $text = "OK - $ms ms - $now"
    }
    else {
        $script:fails++
        if ($script:fails -ge 2) {
            # Segundo fallo seguido (o más): rojo. La hora del corte se
            # apunta sólo la primera vez, para que el mensaje diga desde
            # cuándo no hay conexión; el sonido de corte, igual, sólo una vez.
            if ($script:fails -eq 2) {
                $script:lastDown = $now
                if ($soundItem.Checked -and $script:soundDown) { $script:soundDown.Play() }
            }
            $tray.Icon = $icons.down
            $text = "OFFLINE since $($script:lastDown)"
        }
        else {
            # Primer fallo: naranja, todavía no se considera un corte.
            $tray.Icon = $icons.slow
            $text = "Lost ping - $now"
        }
    }
    # Windows no admite mensajes de más de 63 caracteres en la bandeja
    # (daría error); se corta por si acaso.
    if ($text.Length -gt 63) { $text = $text.Substring(0, 63) }
    $tray.Text = $text
}

# ============================================================
# FINAL
#
# Run() se queda esperando clics y tics del temporizador hasta que se pulsa
# "Exit". Entonces se cierra todo en orden: si no se quita el icono, se
# queda un punto "fantasma" en la bandeja hasta que pasas el ratón por
# encima. "finally" hace que la limpieza se haga aunque algo falle.
try {
    $timer.Start()
    [System.Windows.Forms.Application]::Run()
}
finally {
    $timer.Stop(); $timer.Dispose()
    if ($script:busy) { $pinger.SendAsyncCancel() }   # ping a medias: se cancela
    $pinger.Dispose()
    $tray.Visible = $false; $tray.Dispose()
    $menu.Dispose()
    if ($script:soundDown) { $script:soundDown.Dispose() }
    if ($script:soundUp)   { $script:soundUp.Dispose() }
    $mutex.ReleaseMutex(); $mutex.Dispose()
}
