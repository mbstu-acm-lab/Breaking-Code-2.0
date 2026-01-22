# Windows Setup Guide - Breaking Code 2.0

Quick setup guide for contest PCs. Follow steps in order.

---

## Step 1: Enable PowerShell Scripts

Open **PowerShell as Administrator** and run:

```powershell
Set-ExecutionPolicy RemoteSigned
```
Type `A` and press Enter to accept.

---

## Step 2: Uninstall Old Tools (Optional)

Right-click `uninstall_dev_tools.ps1` → **Run with PowerShell**

---

## Step 3: Create Contest User

Right-click `creatUser.bat` → **Run as administrator**

**Credentials:**
- Username: `BreakingCode2.0`
- Password: `csembstu`

---

## Step 4: Switch User

1. **Log out** of current user
2. Log in as `BreakingCode2.0`

---

## Step 5: Set Wallpaper

Double-click `setWall.bat`

---

## Step 6: Install Development Tools

Right-click `install_dev_tools.ps1` → **Run with PowerShell**

**Installs:** GCC, Java, Python, VS Code, PyCharm, IntelliJ, Code::Blocks, Sublime Text

⏱️ Takes 15-30 minutes

---

## Step 7: Verify Installation

Open **Command Prompt** and test:

```cmd
gcc --version
g++ --version
java --version
python --version
```

All should show version numbers. If not, **restart PC** and try again.

**Expected versions:**
- GCC: 15.2.0
- G++: 15.2.0
- GDB: 17.1
- Java: 25.0.2
- Python: 3.14.x

### If GCC/G++/GDB not found:

**Option 1: Manual Installation via MSYS2**

If MSYS2 MSYS terminal works, open it and run:

```
pacman -Syu
```

Type `Y` and press Enter. Then run:

```
pacman -S --needed --noconfirm base-devel mingw-w64-ucrt-x86_64-toolchain
```

Open a **new** Command Prompt and test again.

**Option 2: Fix PATH Manually**

If still not found, add to System Environment Variables PATH:

```
C:\msys64\ucrt64\bin
```

**If system variable editing is disabled:**

1. Press `Win + R` and type:
   ```
   rundll32 sysdm.cpl,EditEnvironmentVariables
   ```
2. Press `Ctrl + Shift + Enter` (opens with admin privilege)
---

## Step 8: Desktop Shortcuts

1. Remove all existing desktop shortcuts
2. Create new shortcuts on desktop for:
   - Visual Studio Code
   - Sublime Text
   - PyCharm Community Edition
   - IntelliJ IDEA Community Edition
   - Code::Blocks

---

## Step 9: Disable Startup Apps (Optional)

Right-click `disableStartup.ps1` → **Run with PowerShell**

Disables OneDrive, Teams, Discord, Steam, etc.

---

## ✅ Final Checklist

- [ ] GCC works
- [ ] Java works
- [ ] Python works
- [ ] IDEs installed
- [ ] Wallpaper set
- [ ] User `BreakingCode2.0` created

## 🔧 Troubleshooting

**GCC not found?** → Restart PC

**Scripts won't run?** → Run Step 1 again

**Internet still works?** → Flush DNS: `ipconfig /flushdns`

**Restore internet after contest?** → Right-click `resetHosts.bat` → Run as admin

---

**Contest:** Breaking Code 2.0 (IDPC 2026)  
**Organized by:** Department of CSE, MBSTU
