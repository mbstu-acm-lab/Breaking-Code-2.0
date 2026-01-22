<#
.SYNOPSIS
    Silent uninstaller and cleaner for dev tools.
    
.DESCRIPTION
    Attempts to silently uninstall:
    VS Code, CodeBlocks, PyCharm, Python, MinGW, Java, IntelliJ, 
    NetBeans, Eclipse, Sublime Text, MSYS/MSYS2.
    
    Then forcefully removes related directories.
#>

# 1. DEFINE TARGETS
$TargetKeywords = @(
    "Visual Studio Code",
    "CodeBlocks",
    "PyCharm",
    "Python",
    "MinGW",
    "Java",
    "IntelliJ IDEA",
    "NetBeans",
    "Eclipse",
    "Sublime Text",
    "MSYS"
)

# 2. DEFINE FOLDERS TO CLEAN
$CleanupPaths = @(
    # VS Code
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code",
    "$env:APPDATA\Code",
    "$env:USERPROFILE\.vscode",
    
    # CodeBlocks
    "$env:ProgramFiles\CodeBlocks",
    "${env:ProgramFiles(x86)}\CodeBlocks",
    "$env:APPDATA\CodeBlocks",

    # JetBrains (PyCharm, IntelliJ)
    "$env:ProgramFiles\JetBrains",
    "${env:ProgramFiles(x86)}\JetBrains",
    "$env:APPDATA\JetBrains",
    "$env:LOCALAPPDATA\JetBrains",
    "$env:USERPROFILE\.PyCharm*",
    "$env:USERPROFILE\.IntelliJ*",
    
    # Python
    "$env:LOCALAPPDATA\Programs\Python",
    "$env:ProgramFiles\Python*",
    "${env:ProgramFiles(x86)}\Python*",
    
    # MinGW / MSYS
    "C:\MinGW",
    "C:\MinGW64",
    "C:\msys64",
    
    # Java
    "$env:ProgramFiles\Java",
    "${env:ProgramFiles(x86)}\Java",
    
    # NetBeans
    "$env:ProgramFiles\NetBeans*",
    "${env:ProgramFiles(x86)}\NetBeans*",
    "$env:APPDATA\NetBeans",
    "$env:USERPROFILE\.nbi",
    "$env:USERPROFILE\.netbeans",

    # Eclipse (often just a folder, but check common spots)
    "$env:USERPROFILE\eclipse",
    "C:\eclipse",
    "$env:USERPROFILE\.eclipse",
    
    # Sublime Text
    "$env:ProgramFiles\Sublime Text*",
    "${env:ProgramFiles(x86)}\Sublime Text*",
    "$env:APPDATA\Sublime Text*"
)

$RegistryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

Write-Host "Starting AUTO-UNINSTALL process..." -ForegroundColor Cyan

# 3. UNINSTALL LOOP
foreach ($path in $RegistryPaths) {
    $items = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
    
    foreach ($item in $items) {
        if (-not $item.DisplayName) { continue }
        $displayName = $item.DisplayName
        
        foreach ($keyword in $TargetKeywords) {
            if ($displayName -match $keyword) {
                Write-Host "Found: $displayName" -ForegroundColor Green
                
                if ($item.UninstallString) {
                    $uString = $item.UninstallString
                    $argsToUse = ""
                    $cmdToRun = ""

                    # Attempt to detect installer type and add silent flags
                    if ($uString -match "msiexec") {
                         # MSI -> Use /qn /norestart. Ensure /x (uninstall) is present if not capable of running string directly
                         # Often UninstallString is 'MsiExec.exe /I{GUID}' or '/X{GUID}'
                         # We replace /I with /X to force uninstall if I is present, though usually it is /I for 'Modify'
                         
                         if ($uString -match "/I") { 
                            $uString = $uString -replace "/I", "/X" 
                         }
                         $argsToUse = "/qn /norestart"
                         $cmdToRun = "$uString $argsToUse"
                    }
                    elseif ($uString -match "CodeBlocks") {
                        # CodeBlocks usually NSIS
                        $cmdToRun = "`"$($uString -replace '"','' )`" /S"
                    }
                    elseif ($uString -match "Sublime Text") {
                        # Inno Setup
                        $cmdToRun = "`"$($uString -replace '"','' )`" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
                    }
                    elseif ($uString -match "VS Code|Visual Studio Code") {
                        # Inno Setup
                        $cmdToRun = "`"$($uString -replace '"','' )`" /VERYSILENT /NORESTART"
                    }
                    else {
                        # FALLBACK: Try generic silent flag "/S" (works for NSIS, generic)
                        # Remove quotes to wrap cleanly
                        $cleanExe = $uString -replace '"',''
                        $cmdToRun = "`"$cleanExe`" /S"
                    }
                    
                    Write-Host "  > Executing: $cmdToRun" -ForegroundColor Gray
                    
                    try {
                        # We use cmd /c so arguments work predictably
                        Start-Process -FilePath "cmd.exe" -ArgumentList "/c $cmdToRun" -Wait -WindowStyle Hidden
                        Write-Host "  > Uninstaller finished (or kicked off)." -ForegroundColor Green
                    }
                    catch {
                        Write-Host "  > Failed to launch uninstaller." -ForegroundColor Red
                    }
                }
                break 
            }
        }
    }
}

Write-Host "Uninstalls requested. Proceeding to CLEANUP in 5 seconds..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# 4. CLEANUP LOOP
Write-Host "Cleaning folders..." -ForegroundColor Cyan
foreach ($pathPattern in $CleanupPaths) {
    $foundPaths = Get-Item -Path $pathPattern -ErrorAction SilentlyContinue
    foreach ($item in $foundPaths) {
        Write-Host "  Deleting: $($item.FullName)" -ForegroundColor Magenta
        try {
            Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
        } catch {}
    }
}

# 5. CLEANUP PATH ENVIRONMENT VARIABLES
Write-Host "Cleaning PATH environment variables..." -ForegroundColor Cyan

# Paths to remove from system PATH
$pathsToRemove = @(
    "C:\msys64\ucrt64\bin",
    "C:\msys64\mingw64\bin",
    "C:\msys64\usr\bin",
    "C:\MinGW\bin",
    "C:\MinGW64\bin"
)

# Also check for Java and Python paths dynamically
$currentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
$pathArray = $currentPath -split ";"

# Find Java and Python paths in current PATH
foreach ($p in $pathArray) {
    if ($p -match "\\Java\\|\\Python") {
        $pathsToRemove += $p
    }
}

# Remove duplicates
$pathsToRemove = $pathsToRemove | Select-Object -Unique

# Filter out paths that contain dev tool references
$newPathArray = $pathArray | Where-Object {
    $currentPathItem = $_
    $shouldKeep = $true
    
    foreach ($removePattern in $pathsToRemove) {
        if ($currentPathItem -like "*$removePattern*" -or $currentPathItem -eq $removePattern) {
            $shouldKeep = $false
            Write-Host "  Removing from PATH: $currentPathItem" -ForegroundColor Magenta
            break
        }
    }
    
    $shouldKeep
}

# Update the PATH
try {
    $newPath = ($newPathArray | Where-Object { $_ -ne "" }) -join ";"
    [Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::Machine)
    Write-Host "  PATH environment variable cleaned." -ForegroundColor Green
}
catch {
    Write-Host "  Failed to update PATH: $_" -ForegroundColor Red
}

Write-Host "Done." -ForegroundColor Cyan
Start-Sleep -Seconds 3
