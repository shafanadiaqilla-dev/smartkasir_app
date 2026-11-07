@echo off
title SmartKasir Web Server
echo ==================================================
echo   Menjalankan Server Web SmartKasir (P11)...
echo   Alamat: http://localhost:8080
echo.
echo   PENTING:
echo   JANGAN TUTUP JENDELA COMMAND PROMPT INI
echo   selama Anda sedang menggunakan aplikasi SmartKasir!
echo ==================================================
cd /d "%~dp0"

start "" http://localhost:8080
python server.py
pause
