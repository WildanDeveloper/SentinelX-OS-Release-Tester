# SentinelX OS - User Manual

## Welcome to SentinelX OS

SentinelX OS is a next-generation hybrid Linux distribution that combines the best features of Arch Linux and Red Hat Enterprise Linux. This manual will guide you through using your new operating system.

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Package Management](#package-management)
3. [System Configuration](#system-configuration)
4. [Security Management](#security-management)
5. [Backup and Recovery](#backup-and-recovery)
6. [Desktop Environment](#desktop-environment)
7. [System Maintenance](#system-maintenance)
8. [Advanced Features](#advanced-features)

---

## Getting Started

### First Login

After installation, log in with the username and password you created during setup.

### Desktop Overview

SentinelX OS uses **SX Shell**, a modern Wayland-based desktop environment:

- **Super Key** (Windows key): Opens application launcher
- **Super + Return**: Opens terminal
- **Super + Q**: Closes window
- **Super + 1-9**: Switch workspaces

### System Utilities

All SentinelX utilities start with `sx-`:

- `sx-pkg` - Package management
- `sx-config` - System configuration
- `sx-backup` - Backup and recovery
- `sx-monitor` - System monitoring
- `sx-test` - System testing

---

## Package Management

### The sx-pkg Unified Package Manager

SentinelX OS includes a unified package manager that can install packages from:
- Arch Linux repositories (Pacman)
- Red Hat repositories (RPM/DNF)
- Arch User Repository (AUR)

### Basic Commands

**Update package database:**
```bash
sudo sx-pkg update
```

**Install a package:**
```bash
sudo sx-pkg install firefox
```

**Search for packages:**
```bash
sx-pkg search "text editor"
```

**Remove a package:**
```bash
sudo sx-pkg remove firefox
```

**Upgrade all packages:**
```bash
sudo sx-pkg upgrade
```

**List installed packages:**
```bash
sx-pkg list --installed
```

### Package Sources

**Install from specific source:**
```bash
# From Arch repositories
sudo sx-pkg install --pacman firefox

# From Red Hat repositories
sudo sx-pkg install --rpm httpd

# From AUR
sudo sx-pkg install --aur yay
```

### Package Information

**View package details:**
```bash
sx-pkg info firefox
```

**View package dependencies:**
```bash
sx-pkg deps firefox
```

**View package files:**
```bash
sx-pkg files firefox
```

---

## System Configuration

### Using sx-config

The `sx-config` tool manages all system settings from a centralized configuration file.

### View Configuration

**Show all settings:**
```bash
sx-config show
```

**Show specific section:**
```bash
sx-config show system
sx-config show security
sx-config show performance
```

### Modify Settings

**Set a value:**
```bash
sudo sx-config set system.hostname mycomputer
sudo sx-config set system.timezone America/New_York
```

**Apply changes:**
```bash
sudo sx-config apply
```

### Common Configurations

**Change hostname:**
```bash
sudo sx-config set system.hostname sentinelx-laptop
sudo sx-config apply
```

**Configure performance:**
```bash
sudo sx-config set performance.cpu_governor performance
sudo sx-config set performance.swappiness 10
sudo sx-config apply
```

**Network settings:**
```bash
sudo sx-config set network.dns_servers "8.8.8.8,1.1.1.1"
sudo sx-config apply
```

### Export/Import Configuration

**Export configuration:**
```bash
sx-config export json
sx-config export yaml
```

**Import configuration:**
```bash
sudo sx-config import /path/to/config.json
sudo sx-config apply
```

---

## Security Management

SentinelX OS features dual security layers: AppArmor and SELinux.

### AppArmor

**Check AppArmor status:**
```bash
sudo aa-status
```

**Enforce a profile:**
```bash
sudo aa-enforce /etc/apparmor.d/usr.bin.firefox
```

**Set profile to complain mode:**
```bash
sudo aa-complain /etc/apparmor.d/usr.bin.firefox
```

### SELinux

**Check SELinux status:**
```bash
getenforce
```

**View SELinux context:**
```bash
ls -Z /path/to/file
```

**Change file context:**
```bash
sudo chcon -t httpd_sys_content_t /var/www/html/file
```

**View SELinux denials:**
```bash
sudo ausearch -m avc -ts recent
```

### Firewall

**Check firewall status:**
```bash
sudo firewall-cmd --state
```

**Allow a service:**
```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```

**Open a port:**
```bash
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

**List all rules:**
```bash
sudo firewall-cmd --list-all
```

---

## Backup and Recovery

### Automatic Snapshots

SentinelX OS uses Btrfs snapshots for system backup and recovery.

**Create manual snapshot:**
```bash
sudo sx-backup create before-update
```

**Create automatic snapshot:**
```bash
sudo sx-backup auto
```

**List all snapshots:**
```bash
sudo sx-backup list
```

**Delete a snapshot:**
```bash
sudo sx-backup delete snapshot-name
```

### System Rollback

**Rollback to previous snapshot:**
```bash
sudo sx-backup rollback snapshot-name
```

⚠️ **Warning**: Rolling back requires a system reboot and cannot be undone.

### Full System Backup

**Create complete backup:**
```bash
sudo sx-backup backup
```

This creates:
- Btrfs snapshot
- Configuration files backup
- System report

### Scheduled Backups

**Enable automatic daily backups:**
```bash
sudo systemctl enable --now sx-backup.timer
```

**Configure backup schedule:**
Edit `/etc/systemd/system/sx-backup.timer`

---

## Desktop Environment

### SX Shell (Wayland Compositor)

SentinelX OS uses SX Shell, a modern Wayland-based desktop environment.

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Super + Return | Open terminal |
| Super + D | Application launcher |
| Super + Q | Close window |
| Super + Shift + Q | Quit application |
| Super + 1-9 | Switch workspace |
| Super + Shift + 1-9 | Move window to workspace |
| Super + F | Fullscreen |
| Super + Space | Toggle floating |
| Super + Arrow Keys | Navigate windows |

### Customization

**Edit SX Shell config:**
```bash
nano ~/.config/sx-shell/config
```

**Change wallpaper:**
```bash
output * bg /path/to/image.jpg fill
```

**Reload configuration:**
```bash
Super + Shift + R
```

---

## System Maintenance

### System Updates

**Check for updates:**
```bash
sudo sx-pkg update
```

**Install updates:**
```bash
sudo sx-pkg upgrade
```

**Update kernel:**
```bash
sudo sx-pkg upgrade --kernel
sudo reboot
```

### System Monitoring

**Launch system monitor:**
```bash
sx-monitor
```

**Export system report:**
```bash
sx-monitor --export
```

### System Testing

**Run all system tests:**
```bash
sudo sx-test
```

This checks:
- Kernel functionality
- Package management
- Security layers
- Filesystem integrity
- Network connectivity
- System performance

### Cleanup

**Clean package cache:**
```bash
sudo sx-pkg clean
```

**Remove old snapshots:**
```bash
sudo sx-backup cleanup
```

**Clean journal logs:**
```bash
sudo journalctl --vacuum-time=7d
```

### Service Management

**View service status:**
```bash
systemctl status service-name
```

**Start a service:**
```bash
sudo systemctl start service-name
```

**Enable service at boot:**
```bash
sudo systemctl enable service-name
```

**View logs:**
```bash
journalctl -u service-name -f
```

---

## Advanced Features

### Kernel Management

**View current kernel:**
```bash
uname -r
```

**Build custom kernel:**
```bash
cd /usr/src/sentinelx-kernel
sudo ./build.sh
sudo ./install.sh
```

### Container Support

SentinelX OS has native support for containers.

**Using Podman:**
```bash
# Install Podman
sudo sx-pkg install podman

# Run a container
podman run -it ubuntu bash

# List containers
podman ps -a
```

**Using Docker:**
```bash
# Install Docker
sudo sx-pkg install docker

# Enable Docker
sudo systemctl enable --now docker

# Run a container
sudo docker run -it ubuntu bash
```

### Development Environment

**Install development tools:**
```bash
sudo sx-pkg install base-devel git
```

**Set up programming languages:**
```bash
# Python
sudo sx-pkg install python python-pip

# Node.js
sudo sx-pkg install nodejs npm

# Rust
sudo sx-pkg install rust

# Go
sudo sx-pkg install go
```

### Virtualization

**Install KVM/QEMU:**
```bash
sudo sx-pkg install qemu libvirt virt-manager
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt $USER
```

---

## Tips and Tricks

### Quick Tips

1. **Tab Completion**: Press Tab to auto-complete commands and file paths
2. **Command History**: Press Up arrow to cycle through previous commands
3. **Clear Terminal**: Press Ctrl+L or type `clear`
4. **Search History**: Press Ctrl+R and type to search command history

### Performance Optimization

**Optimize boot time:**
```bash
systemd-analyze blame
sudo systemctl disable slow-service
```

**Reduce memory usage:**
```bash
sudo sx-config set performance.swappiness 10
sudo sysctl vm.swappiness=10
```

**Enable TRIM for SSD:**
```bash
sudo systemctl enable --now fstrim.timer
```

### Troubleshooting Commands

```bash
# Check system logs
journalctl -xe

# Check disk usage
df -h

# Check memory usage
free -h

# View running processes
htop

# Test network connectivity
ping -c 4 google.com

# DNS lookup
nslookup google.com
```

---

## Getting Help

### Built-in Help

Most SentinelX utilities have built-in help:
```bash
sx-pkg --help
sx-config --help
sx-backup --help
```

### Man Pages

```bash
man sx-pkg
man sx-config
man sx-backup
```

### Online Resources

- **Official Documentation**: https://docs.sentinelx.org
- **Community Wiki**: https://wiki.sentinelx.org
- **Forum**: https://forum.sentinelx.org
- **Discord**: https://discord.gg/sentinelx

### Support Channels

- **Email**: support@sentinelx.org
- **IRC**: #sentinelx on irc.libera.chat
- **GitHub Issues**: https://github.com/sentinelx/sentinelx-os/issues

---

## Appendix

### System Directories

| Directory | Purpose |
|-----------|---------|
| `/etc/sentinelx/` | System configuration |
| `/var/lib/sentinelx/` | System data |
| `/var/log/sentinelx/` | System logs |
| `/usr/share/sentinelx/` | Shared files |
| `~/.config/sx-shell/` | Desktop configuration |

### Log Files

| Log File | Description |
|----------|-------------|
| `/var/log/sentinelx/system.log` | General system log |
| `/var/log/sentinelx/backup.log` | Backup operations |
| `/var/log/sentinelx/packages.log` | Package operations |

---

**SentinelX OS User Manual**
**Version**: 1.0
**Last Updated**: February 2026

---

<p align="center">
  <strong>SentinelX</strong> — Built for Performance. Designed for Control.
</p>
