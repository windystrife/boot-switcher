@echo off
rem Double-clickable launcher for reboot-to-linux.ps1 (self-elevates to Admin).
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0reboot-to-linux.ps1"
