<#
.SYNOPSIS
    Installs development tools via Winget and configures PATH environment variables.

.DESCRIPTION
    Installs:
    - MinGW (via MSYS2) with GCC/G++/GDB toolchain
    - Java (Microsoft OpenJDK 17)
    - Python (Latest Python 3)
    - Visual Studio Code
    - PyCharm Community
    - IntelliJ IDEA Community
    - Code::Blocks
    - Sublime Text 4

    Updates PATH for:
    - MinGW
    - Java
    - Python

.NOTES
    Must be run as Administrator.
#>

# Check for Administrator privileges and auto-elevate
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "powershell.exe"
    $processInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $processInfo.Verb = "RunAs"
    try {
        [System.Diagnostics.Process]::Start($processInfo)
    }
    catch {
        Write-Error "Failed to elevate privileges. Please run as Administrator manually."
    }
    Exit
}

# WinGet Package IDs
$Packages = @{
    "MinGW (MSYS2)"         = "MSYS2.MSYS2"
    "Java (Latest)"         = "Oracle.JDK.25" 
    "Python 3 (Latest)"     = "Python.Python.3.14"
    "Visual Studio Code"    = "Microsoft.VisualStudioCode"
    "PyCharm Community"     = "JetBrains.PyCharm.Community"
    "IntelliJ Community"    = "JetBrains.IntelliJIDEA.Community"
    "Code::Blocks"          = "CodeBlocks.CodeBlocks"
    "Sublime Text 4"        = "SublimeHQ.SublimeText.4"
}

Write-Host "Starting Installation Process..." -ForegroundColor Cyan
Write-Host "This may take a while depending on your internet connection." -ForegroundColor DarkGray
Write-Host "----------------------------------------"

# Update winget itself first
Write-Host "Updating winget..." -ForegroundColor Yellow
try {
    $updateProc = Start-Process -FilePath "winget" -ArgumentList "upgrade --id Microsoft.Winget.Source --accept-source-agreements" -PassThru -Wait -NoNewWindow
    if ($updateProc.ExitCode -eq 0) {
        Write-Host "  Winget updated successfully." -ForegroundColor Green
    }
    else {
        Write-Host "  Winget update completed with code: $($updateProc.ExitCode)" -ForegroundColor Gray
    }
}
catch {
    Write-Host "  Failed to update winget: $_" -ForegroundColor Yellow
}
Write-Host "----------------------------------------"

# 1. INSTALLATION LOOP
foreach ($appName in $Packages.Keys) {
    $id = $Packages[$appName]
    Write-Host "Installing $appName ($id)..." -ForegroundColor Yellow
    
    # Run winget install
    # -e: Exact match
    # --silent: No UI
    # --accept-*: Auto-accept agreements
    # --force: Force install/upgrade
    $proc = Start-Process -FilePath "winget" -ArgumentList "install --id $id -e --silent --accept-package-agreements --accept-source-agreements --force" -PassThru -Wait
    
    if ($proc.ExitCode -eq 0) {
        Write-Host "  Success." -ForegroundColor Green
    }
    else {
        Write-Host "  Winget reported exit code: $($proc.ExitCode). It might already be installed." -ForegroundColor Gray
    }
    
    # Special handling for MSYS2: Install GCC/G++ toolchain
    if ($id -eq "MSYS2.MSYS2") {
        Write-Host "  Installing GCC/G++ toolchain via pacman..." -ForegroundColor Yellow
        if (Test-Path "C:\msys64\msys2.exe") {
            # Update package database
            Start-Process -FilePath "C:\msys64\msys2.exe" -ArgumentList "-c", "pacman -Syu --noconfirm" -Wait -NoNewWindow
            # Install base-devel and mingw toolchain
            Start-Process -FilePath "C:\msys64\msys2.exe" -ArgumentList "-c", "pacman -S --needed --noconfirm base-devel mingw-w64-ucrt-x86_64-toolchain" -Wait -NoNewWindow
            Write-Host "  GCC/G++ toolchain installed." -ForegroundColor Green
        }
        else {
            Write-Host "  MSYS2 not found. Toolchain installation skipped." -ForegroundColor Yellow
        }
    }
}

Write-Host "----------------------------------------"
Write-Host "Configuring Environment Variables (PATH)..." -ForegroundColor Cyan

# Helper function to add to System PATH
function Add-ToPath {
    param(
        [string]$NewPath
    )
    
    if (-not (Test-Path $NewPath)) {
        Write-Warning "  Path does not exist, skipping: $NewPath"
        return
    }

    # Get current Machine (System) PATH
    $currentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
    
    # Check if already exists (case-insensitive check)
    if ($currentPath -split ";" | Where-Object { $_ -eq $NewPath }) {
        Write-Host "  Already in PATH: $NewPath" -ForegroundColor Gray
    }
    else {
        try {
            $updatedPath = $currentPath.TrimEnd(";") + ";" + $NewPath
            [Environment]::SetEnvironmentVariable("Path", $updatedPath, [EnvironmentVariableTarget]::Machine)
            Write-Host "  Added to PATH: $NewPath" -ForegroundColor Green
        }
        catch {
            Write-Error "  Failed to update PATH: $_"
        }
    }
}

# 2. PATH CONFIGURATION

# A. MinGW (MSYS2)
# Standard install location for MSYS2 is C:\msys64
# We will add ucrt64 (modern default) and mingw64.
Add-ToPath "C:\msys64\ucrt64\bin"
Add-ToPath "C:\msys64\mingw64\bin"

# B. Java
# Oracle JDK installs to C:\Program Files\Java\jdk-<version>\bin
$javaRoot = "C:\Program Files\Java"
if (Test-Path $javaRoot) {
    # Find the latest jdk folder
    $jdkPath = Get-ChildItem -Path $javaRoot -Directory -Filter "jdk*" | Sort-Object Name -Descending | Select-Object -First 1
    if ($jdkPath) {
        Add-ToPath "$($jdkPath.FullName)\bin"
    }
}

# C. Python
# Python installs to various locations.
# WinGet System install -> "C:\Program Files\Python3xx"
# We check Program Files and Program Files (x86)
$pyLocations = @(
    "$env:ProgramFiles\Python*",
    "${env:ProgramFiles(x86)}\Python*"
)

foreach ($loc in $pyLocations) {
    $found = Get-Item $loc -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
    if ($found) {
        Add-ToPath $found.FullName
        Add-ToPath "$($found.FullName)\Scripts"
        break # Only add the latest one found
    }
}

Write-Host "----------------------------------------"
Write-Host "Installation and Configuration Complete." -ForegroundColor Cyan
Write-Host "NOTE: You may need to restart your terminal or computer for PATH changes to take effect." -ForegroundColor Yellow
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
