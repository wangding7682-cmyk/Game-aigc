@echo off
cd /d "%~dp0"
echo ========================================
echo   LLM Proxy Server - Setup
echo ========================================
echo.

where python >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Python not found. Please install Python 3.8+.
    pause
    exit /b 1
)

echo [1/2] Installing dependencies...
pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install dependencies.
    pause
    exit /b 1
)

echo.
echo [2/2] Starting LLM Proxy Server...
echo.
python app.py

pause