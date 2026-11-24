@echo off
chcp 65001 >nul
title PySilInstaller

:: Receive the full path of the caller script (defaults to Installer.bat in current directory)
set "CALLER_BAT=%~1"
if "%CALLER_BAT%"=="" (
    if exist "%CD%\Installer.bat" set "CALLER_BAT=%CD%\Installer.bat"
)

:: Exit immediately if already restarted by PySilInstaller
if defined PYSIL_DONE (
    exit /b 0
)

:: 1. Check if a valid Python installation exists (exclude Microsoft Store alias stub in WindowsApps)
where python >nul 2>nul
if %errorlevel% equ 0 (
    for /f "delims=" %%P in ('where python 2^>nul') do (
        echo "%%P" | findstr /i "WindowsApps" >nul
        if errorlevel 1 (
            python --version >nul 2>nul
            if %errorlevel% equ 0 (
                echo [OK] Python detected:
                python --version
                exit /b 0
            )
        )
    )
)

echo [!] Python not found. Checking winget...
where winget >nul 2>nul
if %errorlevel% neq 0 (
    echo [X] winget is not available on this system.
    echo     Please install Python manually from https://www.python.org/downloads/
    pause >nul
    exit /b 1
)

echo [*] Installing Python silently via winget...
winget install --id Python.Python.3.12 --exact --silent --accept-package-agreements --accept-source-agreements
if %errorlevel% neq 0 (
    echo [X] winget failed to install Python (Error code: %errorlevel%).
    pause >nul
    exit /b 1
)

echo [OK] Python installation completed. Refreshing environment...
timeout /t 2 >nul

:: 2. Reload system and user PATH environment variables
set "PYSIL_DONE=1"
for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%B"
for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USR_PATH=%%B"
set "PATH=%SYS_PATH%;%USR_PATH%;%LocalAppData%\Programs\Python\Python312;%LocalAppData%\Programs\Python\Python312\Scripts"

:: 3. Restart the caller script (e.g., Installer.bat) with updated environment
if exist "%CALLER_BAT%" (
    for %%F in ("%CALLER_BAT%") do set "CALLER_DIR=%%~dpF"
    echo [*] Restarting "%CALLER_BAT%"...
    start "" cmd /c "set PYSIL_DONE=1 && set \"PATH=%PATH%\" && cd /d \"%CALLER_DIR%\" && call \"%CALLER_BAT%\""
    exit
) else (
    echo [OK] Python is ready. (No caller script specified to restart)
    exit /b 0
)