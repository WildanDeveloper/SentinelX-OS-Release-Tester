# SentinelX OS - Complete User Guide

## Table of Contents
1. [Introduction](#introduction)
2. [Installation](#installation)
3. [System Management](#system-management)
4. [Package Management](#package-management)
5. [Performance Tuning](#performance-tuning)
6. [Security](#security)
7. [Monitoring](#monitoring)
8. [Troubleshooting](#troubleshooting)

---

## Introduction

SentinelX OS is a next-generation hybrid Linux distribution combining:
- **Arch Linux** rolling release model
- **Red Hat** enterprise stability
- **Custom optimizations** for performance
- **Dual security layers** (AppArmor + SELinux)

### Key Features
- ⚡ Ultra-fast boot (optimized assembly code)
- 🔧 Hybrid package management (Pacman + DNF)
- 🛡️ Dual security layer (AppArmor + SELinux)
- 📊 Real-time system monitoring
- 🎮 Gaming-optimized mode
- 💾 Atomic updates with snapshots

---

## Installation

### System Requirements
- **CPU:** 64-bit x86_64 processor
- **RAM:** Minimum 4GB (8GB recommended)
- **Storage:** 20GB minimum (SSD recommended)
- **UEFI:** Modern UEFI firmware

### Quick Install
```bash
# Boot from SentinelX ISO
# Run installer
sudo sx-install

# Follow the prompts:
# 1. Select disk
# 2. Choose partitioning
# 3. Set hostname
# 4. Create user
# 5. Install bootloader
```

### Manual Installation
Refer to `docs/INSTALLATION.md` for detailed manual installation steps.

---

## System Management

### System Updates
```bash
# Update entire system
sudo sx-update update

# List available snapshots
sudo sx-update list

# Rollback to snapshot
sudo sx-update rollback <snapshot-name>
```

### Service Management
```bash
# Check system status
systemctl status

# Start/stop services
sudo systemctl start <service>
sudo systemctl stop <service>

# Enable/disable at boot
sudo systemctl enable <service>
sudo systemctl disable <service>
```

---

## Package Management

### Using sx-pkg (Unified Package Manager)

#### Basic Operations
```bash
# Search for packages
sx-pkg search firefox

# Install packages (auto-detects source)
sudo sx-pkg install firefox

# Update all packages
sudo sx-pkg update
sudo sx-pkg upgrade

# Remove packages
sudo sx-pkg remove firefox

# Clean cache
sudo sx-pkg clean
```

#### Source-Specific Installation
```bash
# Force Arch repository
sudo sx-pkg install --arch firefox

# Force Red Hat repository
sudo sx-pkg install --redhat firefox-esr

# Install from AUR
sudo sx-pkg install --aur yay
```

#### Package Information
```bash
# Show package info
sx-pkg info firefox

# List installed packages
sx-pkg list --installed

# Check for updates
sx-pkg check-updates
```

---

## Performance Tuning

### Performance Profiles

#### Desktop Profile (Balanced)
```bash
sudo sx-performance-tuner apply desktop

# Best for: General desktop use, web browsing, office work
# Settings: Balanced CPU, moderate I/O, standard network
```

#### Gaming Profile (Maximum Performance)
```bash
sudo sx-performance-tuner apply gaming

# Best for: Gaming, low-latency applications
# Settings:
# - CPU: performance governor
# - I/O: none scheduler (for NVMe)
# - Network: BBR with 33MB buffers
# - Kernel: ultra-low latency
# - CPU idle states: disabled
```

#### Server Profile
```bash
sudo sx-performance-tuner apply server

# Best for: Servers, high throughput workloads
# Settings: Throughput-optimized for all subsystems
```

#### Laptop Profile (Power Saving)
```bash
sudo sx-performance-tuner apply laptop

# Best for: Laptops, battery life priority
# Settings: Power-efficient settings, minimal background activity
```

### Network Optimization

#### Auto-Optimize Network
```bash
# Detect workload and optimize
sudo sx-network-optimizer optimize

# Specific mode
sudo sx-network-optimizer optimize lowlatency

# Monitor network in real-time
sudo sx-network-optimizer monitor

# Show current status
sx-network-optimizer status
```

#### Network Modes
- **lowlatency:** Gaming, video calls, real-time apps
- **balanced:** General purpose (default)
- **throughput:** Downloads, file transfers

### Check Current Settings
```bash
# Show performance status
sx-performance-tuner status

# Show network status
sx-network-optimizer status
```

---

## Security

### Enable Security Hardening
```bash
# Enable all security features
sudo sx-security enable

# Check security status
sudo sx-security status
```

### Security Features

#### AppArmor
```bash
# Load all profiles
sudo apparmor_parser -r /etc/apparmor.d/*

# Check status
sudo aa-status

# Put profile in complain mode
sudo aa-complain /usr/bin/firefox
```

#### SELinux
```bash
# Check status
getenforce

# Set enforcing
sudo setenforce 1

# View denials
sudo ausearch -m avc -ts recent
```

#### Firewall
```bash
# UFW (Ubuntu Firewall)
sudo ufw status
sudo ufw allow 8080/tcp
sudo ufw deny from 192.168.1.100

# firewalld (Red Hat)
sudo firewall-cmd --list-all
sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --reload
```

---

## Monitoring

### System Health Monitor

#### Start Monitoring
```bash
# Interactive monitoring
sudo sx-health-monitor start

# One-time check
sudo sx-health-monitor check

# Show status
sx-health-monitor status

# View alert history
sx-health-monitor alerts
```

#### Health Thresholds
- **CPU Temperature:** Warning at 70°C, Critical at 85°C
- **Memory Usage:** Warning at 85%, Critical at 95%
- **Disk Space:** Warning at 85%, Critical at 95%
- **Load Average:** Warning at 2x CPU count, Critical at 4x

### Resource Monitoring
```bash
# Real-time resource usage
htop

# Disk usage
df -h

# Memory usage
free -h

# I/O statistics
iostat -x 1

# Network statistics
iftop
```

### Log Analysis
```bash
# System logs
sudo journalctl -xe

# Follow logs
sudo journalctl -f

# Service logs
sudo journalctl -u <service>

# Filter by priority
sudo journalctl -p err
```

---

## Troubleshooting

### Boot Issues

#### System Won't Boot
```bash
# Boot from live USB
# Chroot into system
mount /dev/sdX2 /mnt
arch-chroot /mnt

# Reinstall bootloader
grub-install --target=x86_64-efi --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg
```

#### Kernel Panic
```bash
# Boot with previous kernel
# At GRUB menu, select "Advanced options"
# Choose older kernel version

# After booting, remove problematic kernel
sudo pacman -R linux
```

### Performance Issues

#### System Slow
```bash
# Check CPU usage
top

# Check disk I/O
sudo iotop

# Check memory
free -h

# Apply performance profile
sudo sx-performance-tuner apply desktop

# Clear caches
sudo sync
echo 3 | sudo tee /proc/sys/vm/drop_caches
```

#### High Memory Usage
```bash
# Check memory hogs
ps aux --sort=-%mem | head

# Check for memory leaks
sudo valgrind --leak-check=full <program>

# Enable zram compression
sudo modprobe zram
echo lz4 > /sys/block/zram0/comp_algorithm
echo 4G > /sys/block/zram0/disksize
sudo mkswap /dev/zram0
sudo swapon /dev/zram0
```

### Network Issues

#### No Internet Connection
```bash
# Check interface status
ip link

# Bring interface up
sudo ip link set <interface> up

# Restart NetworkManager
sudo systemctl restart NetworkManager

# Check DNS
cat /etc/resolv.conf

# Test connectivity
ping -c 4 8.8.8.8
```

#### Slow Network
```bash
# Optimize network
sudo sx-network-optimizer optimize

# Check for packet loss
ping -c 100 8.8.8.8

# Test bandwidth
speedtest-cli

# Check network stats
ss -s
netstat -i
```

### Package Issues

#### Package Installation Fails
```bash
# Update package database
sudo sx-pkg update

# Clear cache
sudo sx-pkg clean

# Force reinstall
sudo sx-pkg install --force <package>

# Check for conflicts
sx-pkg info <package>
```

#### Dependency Conflicts
```bash
# Use dependency resolver
sudo python3 packages/sx-resolver.py <package>

# Force remove conflicting package
sudo sx-pkg remove --nodeps <package>

# Reinstall with dependencies
sudo sx-pkg install <package>
```

### System Recovery

#### Restore from Snapshot
```bash
# List snapshots
sudo sx-update list

# Boot from recovery
# At GRUB, select recovery mode

# Rollback
sudo sx-update rollback <snapshot-name>

# Reboot
sudo reboot
```

#### Reset to Defaults
```bash
# Backup user data
cp -r /home/<user> /backup/

# Restore default configs
sudo sx-config restore-defaults

# Rebuild package database
sudo sx-pkg rebuild-db
```

---

## Advanced Topics

### Custom Kernel Compilation
```bash
cd kernel/
sudo ./build.sh
sudo ./install.sh
```

### Creating Custom Profiles
```bash
# Edit performance tuner config
sudo nano /etc/sx/performance.conf

# Add custom profile
[custom]
cpu_governor=performance
io_scheduler=none
swappiness=10
```

### Automation Scripts
```bash
# Create startup script
sudo nano /etc/sx/startup.sh

# Make executable
sudo chmod +x /etc/sx/startup.sh

# Enable at boot
sudo systemctl enable sx-startup.service
```

---

## Getting Help

### Documentation
- **Installation Guide:** `docs/INSTALLATION.md`
- **API Documentation:** `docs/API.md`
- **Development Guide:** `DEVELOPMENT.md`

### Commands Help
```bash
# Tool-specific help
sx-pkg --help
sx-performance-tuner --help
sx-network-optimizer help
sx-health-monitor help
```

### Community
- **GitHub:** https://github.com/WildanDev/SentinelX-OS
- **Wiki:** https://github.com/WildanDev/SentinelX-OS/wiki
- **Issues:** Report bugs and request features

---

## Appendix

### Keyboard Shortcuts (Sway)
- `Super+Enter` - Terminal
- `Super+D` - Application launcher
- `Super+Shift+Q` - Close window
- `Super+[1-9]` - Switch workspace

### System Paths
- **Configuration:** `/etc/sx/`
- **Logs:** `/var/log/sx-*.log`
- **Cache:** `/var/cache/sx-pkg/`
- **Snapshots:** `/.snapshots/`

### Default Credentials
- **Username:** Created during installation
- **Root:** Disabled by default (use sudo)

---

**SentinelX OS** — Built for Performance. Designed for Control.

© 2026 SentinelX. All rights reserved.
