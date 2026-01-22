@echo off
:: Check if running as admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting admin privileges...
    powershell Start-Process "%~f0" -Verb RunAs
    exit /b
)

set "sourceHosts=%~dp0hosts"
set "targetHosts=%SystemRoot%\System32\drivers\etc\hosts"

:: Check if source hosts file exists
if not exist "%sourceHosts%" (
    echo ERROR: hosts file not found in current directory: %sourceHosts%
    echo Please ensure the hosts file is in the same directory as this script.
    pause
    exit /b 1
)

echo ========================================
echo This will replace the system hosts file with:
echo %sourceHosts%
echo.
echo Target location:
echo %targetHosts%
echo ========================================
set /p confirm="Do you want to continue? (yes/no): "
if /i not "%confirm%"=="yes" (
    echo Operation cancelled.
    pause
    exit /b
)

echo.
echo Taking ownership of hosts file...
takeown /f "%targetHosts%"
if %errorLevel% neq 0 (
    echo ERROR: Failed to take ownership of hosts file.
    pause
    exit /b 1
)

echo Granting permissions...
icacls "%targetHosts%" /grant "%username%:F"
if %errorLevel% neq 0 (
    echo ERROR: Failed to grant permissions.
    pause
    exit /b 1
)

echo Creating backup...
copy "%targetHosts%" "%targetHosts%.bak"
if %errorLevel% equ 0 (
    echo Backup saved to: %targetHosts%.bak
) else (
    echo WARNING: Failed to create backup.
)

echo Copying new hosts file...
copy /Y "%sourceHosts%" "%targetHosts%"
if %errorLevel% neq 0 (
    echo ERROR: Failed to copy hosts file.
    pause
    exit /b 1
)

echo Flushing DNS cache...
ipconfig /flushdns >nul 2>&1

echo.
echo SUCCESS: System hosts file has been updated!
echo You may need to restart your browser for changes to take effect.
pause
