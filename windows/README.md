# Windows Scripts for Contest Environment Setup

This directory contains scripts for setting up Windows systems for the Breaking Code 2.0 programming contest (IDPC 2026).

## Prerequisites

### PowerShell Execution Policy
PowerShell scripts require appropriate execution policy. You have two options:

**Option 1: Run with Bypass (Recommended for one-time use)**
```powershell
powershell -ExecutionPolicy Bypass -File scriptname.ps1
```

**Option 2: Set Policy Permanently (As Administrator)**
```powershell
Set-ExecutionPolicy RemoteSigned
```

Note: The scripts will auto-elevate to Administrator privileges when needed.

---

## Setup Instructions

Follow these steps in order to prepare a contest PC:

### 1. **Uninstall Existing Development Tools**
Remove any previously installed development tools to ensure a clean environment.

**Script:** `uninstall_dev_tools.ps1`

**What it does:**
- Uninstalls VS Code, PyCharm, IntelliJ IDEA, Code::Blocks, Sublime Text
- Removes Python, Java, MinGW/MSYS2
- Deletes configuration directories
- Cleans PATH environment variables

**Usage:**
```powershell
powershell -ExecutionPolicy Bypass -File uninstall_dev_tools.ps1
```
or right-click → "Run with PowerShell"

---

### 2. **Create Contest User Account**
Create a standardized user account for contestants.

**Script:** `creatUser.bat`

**Credentials:**
- Username: `BreakingCode2.0`
- Password: `csembstu`
- Privileges: Administrator

**Usage:**
```cmd
Right-click creatUser.bat → Run as administrator
```

---

### 3. **Log in to New User**
1. Log out of current user
2. Log in as `BreakingCode2.0` with password `csembstu`
3. Continue with remaining steps

---

### 4. **Set Wallpaper**
Apply contest branding wallpaper.

**Script:** `setWall.bat`

**Requirements:** `wall.jpg` must be in the same directory

**Usage:**
```cmd
Double-click setWall.bat
```

---

### 5. **Install Development Tools**
Install all required programming tools and IDEs.

**Script:** `install_dev_tools.ps1`

**Installs:**
- MinGW (MSYS2) with GCC/G++/GDB toolchain
- Java (OpenJDK 25)
- Python 3.14
- Visual Studio Code
- PyCharm Community Edition
- IntelliJ IDEA Community Edition
- Code::Blocks
- Sublime Text 4

**Configures:**
- System PATH for MinGW, Java, Python
- Updates winget before installation

**Usage:**
```powershell
powershell -ExecutionPolicy Bypass -File install_dev_tools.ps1
```
or right-click → "Run with PowerShell"

**Note:** This process may take 15-30 minutes depending on internet speed.

---

### 6. **Verify Installation**
Check that all tools are properly installed and accessible.

**Open Command Prompt or PowerShell and run:**

```cmd
# Check GCC/G++
gcc --version
g++ --version
gdb --version

# Check Java
java --version
javac --version

# Check Python
python --version

# Check IDEs (try launching)
code --version
```

**Expected Results:**
- All commands should return version information
- No "command not found" errors

**If verification fails:**
- Restart your computer for PATH changes to take effect
- Re-run the install script

---

### 7. **Apply Network Restrictions (Hosts File)**
Block access to search engines, documentation sites, and online judges (except toph.co).

**Script:** `applyHosts.bat`

**Blocks:**
- Search engines (Google, Bing, Yahoo, DuckDuckGo, etc.)
- Documentation sites (cppreference, GeeksforGeeks, W3Schools, MDN, etc.)
- Online judges (Codeforces, AtCoder, LeetCode, etc.)
- AI assistants (ChatGPT, Claude, Bard, etc.)

**Allows:**
- toph.co (contest submission platform)
- localhost

**Usage:**
```cmd
Right-click applyHosts.bat → Run as administrator
```

**Creates backup:** `C:\Windows\System32\drivers\etc\hosts.bak`

---

### 8. **Disable Startup Applications (Optional)**
Improve boot time and reduce distractions.

**Script:** `disableStartup.ps1`

**Disables:**
- OneDrive, Teams, Discord, Spotify, Steam, etc.
- Update services, cloud sync applications
- Background applications

**Keeps enabled:**
- Windows Defender
- Security services
- System critical processes

**Usage:**
```powershell
powershell -ExecutionPolicy Bypass -File disableStartup.ps1
```

**Creates backup:** Desktop folder with timestamp

---

## Post-Setup Verification Checklist

- [ ] User `BreakingCode2.0` created and logged in
- [ ] Contest wallpaper applied
- [ ] GCC/G++/GDB working (`gcc --version`)
- [ ] Java working (`java --version`)
- [ ] Python working (`python --version`)
- [ ] IDEs installed (VS Code, PyCharm, IntelliJ, Code::Blocks, Sublime)
- [ ] Google.com blocked (open browser and test)
- [ ] toph.co accessible (open browser and test)
- [ ] Startup apps disabled (optional)

---

## Troubleshooting

### Scripts won't run (Execution Policy Error)
```powershell
# Run this as Administrator
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### PATH not updated after installation
- Restart your computer
- Or log out and log back in

### GCC not found after MSYS2 installation
- Re-run install script
- Check if `C:\msys64\ucrt64\bin` exists
- Manually verify PATH in System Environment Variables

### Hosts file not applying
- Run `ipconfig /flushdns` in Command Prompt
- Restart browser
- Check `C:\Windows\System32\drivers\etc\hosts` file

### Restore blocked websites after contest
```cmd
Right-click resetHosts.bat → Run as administrator
```

---

## File Descriptions

| File | Purpose |
|------|---------|
| `install_dev_tools.ps1` | Installs all development tools via winget |
| `uninstall_dev_tools.ps1` | Removes all dev tools and cleans system |
| `creatUser.bat` | Creates contest user with admin privileges |
| `setWall.bat` | Sets desktop wallpaper from wall.jpg |
| `applyHosts.bat` | Applies network restrictions via hosts file |
| `resetHosts.bat` | Restores default hosts file |
| `disableStartup.ps1` | Disables startup applications |
| `hosts` | Custom hosts file with blocklist |
| `wall.jpg` | Contest wallpaper image |

---

## Important Notes

1. **Administrator privileges required** for all scripts except `setWall.bat`
2. **Internet connection required** for installation script
3. **Backup created automatically** before modifying system files
4. **Contest duration**: Run these scripts before the contest starts
5. **After contest**: Use `resetHosts.bat` to restore internet access

---

## Support

For issues during setup:
- Check the troubleshooting section above
- Verify prerequisites are met
- Ensure running as Administrator
- Check internet connection for installations

**Organized by:** Department of CSE, MBSTU  
**Contest:** Breaking Code 2.0 (IDPC 2026)
