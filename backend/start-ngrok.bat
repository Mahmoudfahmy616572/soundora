@echo off
cd /d C:\Users\AG\soundora\backend
del ngrok-url.log 2>nul
"C:\Users\AG\ngrok\ngrok.exe" http 8000 --url=https://overplant-gutter-bleak.ngrok-free.dev --log=stdout > ngrok-url.log 2>&1
