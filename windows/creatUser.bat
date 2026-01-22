@echo off
:: Check if running as admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting admin privileges...
    powershell Start-Process "%~f0" -Verb RunAs
    exit /b
)

net user "BreakingCode2.0" "csembstu" /add
net localgroup "Administrators" "BreakingCode2.0" /add
echo User "BreakingCode2.0" has been added to the Administrators group successfully.
