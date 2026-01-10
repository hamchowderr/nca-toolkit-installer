@echo off
cd /d C:\Users\HamCh\code\nca-toolkit-installer
"C:\Program Files\Git\cmd\git.exe" add -A
"C:\Program Files\Git\cmd\git.exe" status
"C:\Program Files\Git\cmd\git.exe" commit -m "Replace deploy.cloud.run with Cloud Shell approach"
"C:\Program Files\Git\cmd\git.exe" push origin main
pause
