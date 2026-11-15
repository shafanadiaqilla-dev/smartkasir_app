@echo off
title SmartKasir Web Server
echo ==================================================
echo   Menjalankan Server Web SmartKasir (P12)...
echo.
echo   PENTING:
echo   JANGAN TUTUP JENDELA INI SELAMA MEMBUKA WEB!
echo ==================================================
cd /d "%~dp0"

where python >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    python server.py
    goto end
)

where py >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    py server.py
    goto end
)

echo [INFO] Python tidak terdeteksi di PATH, menjalankan via Flutter Chrome...
start "" http://localhost:8080
flutter run -d chrome --web-port=8080

:end
pause
