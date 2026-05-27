@echo off
echo ══════════════════════════════════════════
echo   DOCAVE Backend - Instalacion y arranque
echo ══════════════════════════════════════════

echo.
echo [1/4] Creando entorno virtual...
python -m venv venv

echo.
echo [2/4] Activando entorno virtual...
call venv\Scripts\activate

echo.
echo [3/4] Instalando dependencias...
pip install -r requirements.txt

echo.
echo [4/4] Aplicando migraciones...
python manage.py makemigrations users tasks notes reminders
python manage.py migrate

echo.
echo ✅ Backend listo. Iniciando servidor...
echo    URL: http://127.0.0.1:8000
echo.
python manage.py runserver
