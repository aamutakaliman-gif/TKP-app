@echo off
cd /d %~dp0
if not exist .venv (
  python -m venv .venv || (echo Python belum terpasang. Jalankan: winget install Python.Python.3.12 & pause & exit /b)
  .venv\Scripts\pip install -r requirements.txt
)
echo.
echo Alamat IP laptop ini (pakai yang Wi-Fi, tulis di aplikasi: http://IP:8000):
ipconfig | findstr /C:"IPv4"
echo.
netsh advfirewall firewall show rule name="TKP Server 8000" >nul 2>&1 || netsh advfirewall firewall add rule name="TKP Server 8000" dir=in action=allow protocol=TCP localport=8000 >nul 2>&1 || echo [!] Firewall belum dibuka. Jalankan file ini sekali sebagai Administrator.
.venv\Scripts\python server.py
pause
