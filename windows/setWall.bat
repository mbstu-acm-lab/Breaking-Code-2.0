@echo off
set "wallpaperPath=%~dp0wall.jpg"
reg add "HKCU\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "%wallpaperPath%" /f
RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters
echo Wallpaper changed successfully!
