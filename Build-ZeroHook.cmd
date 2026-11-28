@echo off
rem Builds ZeroHook.exe from ZeroHook.ps1 (see Build-ZeroHook.ps1). Close ZeroHook before building.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build-ZeroHook.ps1" %*
echo.
pause
