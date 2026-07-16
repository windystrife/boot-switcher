@echo off
rem Double-clickable launcher for reboot-to-windows.ps1 (self-elevates to Admin).
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0reboot-to-windows.ps1"
