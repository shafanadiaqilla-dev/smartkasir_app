@echo off
title SmartKasir Web Server
echo ==================================================
echo   Server SmartKasir Sedang Berjalan!
echo   Alamat: http://localhost:8080
echo.
echo   PENTING:
echo   JANGAN TUTUP JENDELA COMMAND PROMPT INI
echo   selama Anda sedang menggunakan aplikasi SmartKasir.
echo ==================================================
cd /d "%~dp0"
timeout /t 1 /nobreak >nul
start "" http://localhost:8080
python -m http.server 8080 --directory build/web
pause
