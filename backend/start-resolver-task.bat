@echo off
cd /d C:\Users\AG\soundora\backend
del tunnel-url.log 2>nul
del uvicorn.log 2>nul
start "SB" /b cmd /c "python -m uvicorn main:app --host 0.0.0.0 --port 8000 > uvicorn.log 2>&1"
timeout /t 6 /nobreak >nul
"C:\Users\AG\cloudflared\cloudflared.exe" tunnel --url http://localhost:8000 --no-autoupdate > tunnel-url.log 2>&1
