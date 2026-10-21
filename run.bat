@echo off
rem One-click launcher: start the Python server, then the 3D game.
rem Needs Python 3.10+ on PATH. Run from anywhere; paths are relative to this file.
cd /d "%~dp0"

where python >nul 2>nul
if errorlevel 1 (
    echo Khong tim thay Python. Cai Python 3.10+ va tick "Add python.exe to PATH".
    pause
    exit /b 1
)

start "Bloxorz server" python -m bloxorz.server

if exist "gui\export\Bloxorz.exe" (
    rem give the server a moment to open port 5555; the game also reconnects later
    timeout /t 1 /nobreak >nul
    start "" "gui\export\Bloxorz.exe"
) else if exist "tools\godot\Godot_v4.7.2-stable_win64.exe" (
    timeout /t 1 /nobreak >nul
    start "" "tools\godot\Godot_v4.7.2-stable_win64.exe" --path gui
) else (
    echo Chua co gui\export\Bloxorz.exe - tai tu link Google Drive trong bao cao,
    echo hoac chay: python tools/get_godot.py  roi chay lai run.bat
    pause
)
