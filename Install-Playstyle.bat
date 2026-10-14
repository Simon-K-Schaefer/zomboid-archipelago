@echo off
cd /d "%~dp0"
echo.
echo Project Zomboid Archipelago v1.6 - Choose ONE playstyle

echo   1. Base Building      (41 checks)
echo   2. Local Exploration (33 checks)
echo   3. Road Trip         (39 checks)
echo.
choice /C 123 /N /M "Select 1, 2 or 3: "
if errorlevel 3 set "STYLE=road_trip"&goto run
if errorlevel 2 set "STYLE=local_exploration"&goto run
set "STYLE=base_building"
:run
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Install-Playstyle.ps1" -Style "%STYLE%"
echo.
if errorlevel 1 echo Installation stopped. Read the error above, and see docs\INSTALL_WINDOWS.md.
pause
