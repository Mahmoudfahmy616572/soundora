@echo off
cd /d C:\Users\AG\soundora\backend
start "Soundora Backend" cmd /k python -m uvicorn main:app --host 0.0.0.0 --port 8000
timeout /t 6 /nobreak >nul
start "ngrok Tunnel" cmd /k "C:\Users\AG\ngrok\ngrok.exe" http 8000 --url=https://overplant-gutter-bleak.ngrok-free.dev
echo.
echo Backend + tunnel running. Keep both windows open.
echo Resolver URL: https://overplant-gutter-bleak.ngrok-free.dev
echo This URL never changes - no code updates needed.
pause
