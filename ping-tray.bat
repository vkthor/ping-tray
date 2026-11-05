@echo off
rem ping-tray.bat - Arranca ping-tray.ps1 (en esta misma carpeta) sin ventana.
start "" "%SystemRoot%\System32\conhost.exe" --headless "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0ping-tray.ps1" -Hidden
