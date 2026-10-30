@echo off
title SmartKasir - Chrome Runner
echo ==================================================
echo   Menjalankan SmartKasir langsung di Google Chrome
echo ==================================================
cd /d "%~dp0"
flutter run -d chrome
pause
