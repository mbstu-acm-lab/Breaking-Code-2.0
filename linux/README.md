# Linux Scripts for Ubuntu 24.04 LTS

This directory contains bash scripts equivalent to the Windows batch/PowerShell scripts for Ubuntu 24.04 LTS.

## Scripts

### install_dev_tools.sh
Installs development tools including:
- GCC/G++ (build-essential)
- Java (OpenJDK)
- Python 3.14 (or latest available)
- Visual Studio Code
- PyCharm Community
- IntelliJ IDEA Community
- Code::Blocks
- Sublime Text 4

**Usage:**
```bash
chmod +x install_dev_tools.sh
./install_dev_tools.sh
```

### uninstall_dev_tools.sh
Uninstalls all development tools and removes their configuration directories.

**Usage:**
```bash
chmod +x uninstall_dev_tools.sh
./uninstall_dev_tools.sh
```

### createUser.sh
Creates a new user with sudo privileges.
- Username: BreakingCode2.0
- Password: csembstu

**Usage:**
```bash
chmod +x createUser.sh
./createUser.sh
```

### setWall.sh
Sets the desktop wallpaper from `wall.jpg` in the same directory.
Supports GNOME, KDE, XFCE, and fallback to feh.

**Usage:**
```bash
chmod +x setWall.sh
./setWall.sh
```

### resetHosts.sh
Resets the `/etc/hosts` file to Ubuntu default state.

**Usage:**
```bash
chmod +x resetHosts.sh
./resetHosts.sh
```

### applyHosts.sh
Applies the custom `hosts` file from the parent directory to `/etc/hosts`.

**Usage:**
```bash
chmod +x applyHosts.sh
./applyHosts.sh
```

## Making Scripts Executable

To make all scripts executable at once:
```bash
chmod +x *.sh
```

## Notes

1. All scripts that require root privileges will automatically request sudo elevation.
2. Scripts include confirmation prompts before destructive operations.
3. Backups are created before modifying system files.
4. DNS cache is flushed after hosts file modifications.
5. Some packages (like Python 3.14) may not be available in official repositories and will fall back to the latest available version.

## Requirements

- Ubuntu 24.04 LTS (may work on other Debian-based distributions)
- Internet connection for package downloads
- Sudo privileges
