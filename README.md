# ping-tray

**English** | [Español](README.es.md)

**A colored dot in the Windows system tray that tells you whether you're online.** One readable PowerShell script, nothing to install, no admin rights, and about 100 KB of traffic per hour.

| Color | Meaning |
|---|---|
| 🟢 Green | Connection is fine |
| 🟠 Orange | Slow (over 400 ms) or a single lost ping |
| 🔴 Red | No connection (two lost pings in a row) |
| ⚪ Gray | Starting up |

![The three colors of the dot: green, orange and red](docs/img/estados.png)

Hover over it to see the latency and the time, or since when you've been offline:

![Connected: OK, 5 ms](docs/img/tooltip-ok.png) ![Offline since 12:29:27](docs/img/tooltip-offline.png)

## Why I use it

I travel a lot by train and work tethered to my phone's hotspot. That connection comes and goes: tunnels, dead zones, cell handovers. I used to keep a `ping -t 8.8.8.8` window open and check it whenever something felt slow, to know whether the problem was the network or the website.

ping-tray does the same without a window: one glance at the tray and you know whether it's worth waiting or you're in a tunnel.

## What it does, exactly

- It sends an 8-byte ping to `8.8.8.8` every 3 seconds. That's about **100 KB per hour**, versus ~430 KB/h for `ping -t` (one 32-byte ping per second).
- It tolerates a single lost ping (orange, not red), because on a mobile connection that's normal and doesn't mean the connection is down.
- **Nothing to install, no admin rights**, and **it doesn't change anything on your system**: no services, no network settings, no configuration. The only things it may create, and only if you ask, are what it needs to open by itself when you sign in (with **Start with Windows**) and a key in your part of the registry to remember that you want sound (with **Sound**).
- It's two files: [`ping-tray.ps1`](ping-tray.ps1), the program, and [`ping-tray.bat`](ping-tray.bat), one line that starts it without a window. Read them before you use them.

## How to use it

You need Windows 10 or 11. Nothing else to install. (Tested on Windows 11.)

### Option A (recommended): download it

1. Go to the [latest release](https://github.com/vkthor/ping-tray/releases/latest) and download both files: **`ping-tray.ps1`** and **`ping-tray.bat`**.
2. Put them together in the same folder, whichever you like (for example, `Documents\ping-tray`).
3. Double-click **`ping-tray.bat`**. The dot appears in the tray (you may have to open the little `^` arrow to see it; drag it out if you want it always visible).

### Option B: with a single line

It does the same as option A, without visiting the page: it downloads both files to the `%LOCALAPPDATA%\ping-tray` folder and starts it. `%LOCALAPPDATA%` is a folder of your user account that is normally at `C:\Users\<your user>\AppData\Local`, so the files end up in `C:\Users\<your user>\AppData\Local\ping-tray`. Open PowerShell (right-click the Start button → **Terminal**) and paste:

```powershell
$d = "$env:LOCALAPPDATA\ping-tray"; mkdir $d -Force > $null; 'ping-tray.ps1', 'ping-tray.bat' | ForEach-Object { irm "https://github.com/vkthor/ping-tray/releases/latest/download/$_" -OutFile "$d\$_" }; & "$d\ping-tray.bat"
```

The dot appears and you can close the window. From then on it works just like option A, offline too. To start it again, double-click `ping-tray.bat` in that folder (or tick **Start with Windows**). If you paste the line again, it downloads the latest version over the old one.

### The menu

Click the dot, with either mouse button:

- **Start with Windows**: when ticked, ping-tray opens by itself every time you sign in to Windows. Untick it the same way. It also shows up in Task Manager, under **Startup apps**, as ping-tray, and you can enable or disable it there: the tick in the menu follows whatever you choose. It remembers which folder the script is in: if you move it, untick and tick it again.
- **Sound**: when ticked, it plays a warning when the connection drops (turns red) and a different sound when it comes back. A single lost ping or a slow moment doesn't make a sound. It's off by default; if you turn it on, it remembers it for next time. It uses two sounds that come with Windows, from the old speech recognition feature, so they don't get mixed up with the usual alerts. They're recorded very quietly, so ping-tray turns them up (without changing the Windows volume); the level can be set in the script's settings.
- **About**: version and a link to this page.
- **Exit**: closes it.

Only one instance (one running copy) can exist at a time. If you start it again while it's running, the second instance detects that the first is still running and quietly closes: you always end up with a single dot.

### Add it to the Start menu (optional)

ping-tray doesn't add itself to the Start menu, but you can do it with one command. Open PowerShell and paste this line, replacing what's inside the first quotes with the folder where your `ping-tray.bat` is (as it is, it works for option B):

```powershell
$dir = "$env:LOCALAPPDATA\ping-tray"; $s = (New-Object -ComObject WScript.Shell).CreateShortcut("$([Environment]::GetFolderPath('Programs'))\ping-tray.lnk"); $s.TargetPath = "$dir\ping-tray.bat"; $s.WorkingDirectory = $dir; $s.WindowStyle = 7; $s.Save()
```

For example, if you keep it in `Documents\ping-tray`, the line would start with `$dir = "C:\Users\<your user>\Documents\ping-tray";`.

**ping-tray** appears in the Start menu's app list, and you can pin it from there. It has the generic `.bat` icon. If you move the folder, remove it and create it again. To remove it:

```powershell
Remove-Item "$([Environment]::GetFolderPath('Programs'))\ping-tray.lnk"
```

### Remove it

Untick **Start with Windows** and **Sound**, click **Exit** and delete the folder (with option B, the folder is `C:\Users\<your user>\AppData\Local\ping-tray`; to get there quickly, type `%LOCALAPPDATA%\ping-tray` in File Explorer's address bar). If you added it to the Start menu, remove that too with the command above. Nothing else is left behind.

## Changing the target or other settings

Open `ping-tray.ps1` in Notepad. The settings are at the top: what to ping, how often, how long to wait for a reply, from how many milliseconds a reply counts as slow, and which sounds to use and how loud. Change whatever you like, save, then exit and start the dot again.

## Why a `.ps1` and not an `.exe`

Because anyone can open it and see what it does. A program that runs in the background all the time and uses the network should be readable in five minutes.

Also, with either option, what runs is always the copy on your PC, not something downloaded at that moment. So the indicator starts even when there's no internet, which is exactly when you need it most.

## Questions

**Why 8.8.8.8?** It's Google's DNS: it answers pings from almost any network and is almost never down. You can change it to `1.1.1.1` (Cloudflare) in the script's settings.

**Windows says the script isn't signed or can't be run.** By default, Windows blocks PowerShell scripts. The `.bat` uses `-ExecutionPolicy Bypass` only for this script, without changing the system policy.

**Windows shows a security warning when opening the `.bat`.** Windows marks files downloaded from the internet, and when you open a downloaded `.bat` it may ask whether you want to run it ("Security Warning" or "Windows protected your PC"). That's normal for any program downloaded outside a store. To stop it asking: right-click `ping-tray.bat` → **Properties** → tick **Unblock** → **OK**. Do the same with `ping-tray.ps1`.

**My antivirus warns about or blocks ping-tray.** Some antivirus programs distrust any PowerShell script that runs without a window, because malware does that too. ping-tray downloads nothing and sends nothing but the pings. If your antivirus blocks it, read the script and, if you're happy with it, add it to its exceptions.

**A black window flashes briefly when I double-click the `.bat` (or when I sign in, with Start with Windows).** That's normal: it's the `.bat` itself closing. The dot keeps running without a window.

**Does it work with a VPN?** Yes. It checks whether you can reach the internet through whatever route the PC is using at the moment.

## License

[GPL-3.0](LICENSE) © 2026 Víctor Cruz
