# SentinelX OS - Complete Installation Guide

## Table of Contents
1. [System Requirements](#system-requirements)
2. [Pre-Installation](#pre-installation)
3. [Installation Methods](#installation-methods)
4. [Post-Installation](#post-installation)
5. [Troubleshooting](#troubleshooting)

---

## System Requirements

### Minimum Requirements
- **CPU**: x86_64 processor (64-bit)
- **RAM**: 4 GB
- **Storage**: 20 GB free disk space
- **Graphics**: Any GPU with basic graphics support
- **Network**: Internet connection (for package downloads)

### Recommended Requirements
- **CPU**: Multi-core x86_64 processor
- **RAM**: 8 GB or more
- **Storage**: 50 GB SSD
- **Graphics**: Modern GPU with Vulkan support
- **Network**: Broadband internet connection

---

## Pre-Installation

### 1. Download SentinelX OS ISO

Download the latest ISO image from:
```
https://sentinelx.org/download
```

Verify the checksum:
```bash
sha256sum sentinelx-*.iso
```

### 2. Create Bootable USB

**On Linux:**
```bash
sudo dd if=sentinelx-*.iso of=/dev/sdX bs=4M status=progress && sync
```

**On Windows:**
- Use Rufus or Etcher to create bootable USB

**On macOS:**
```bash
sudo dd if=sentinelx-*.iso of=/dev/diskX bs=4m
```

### 3. Boot from USB

1. Enter BIOS/UEFI settings (usually F2, F12, Del, or Esc)
2. Disable Secure Boot (if applicable)
3. Set USB as first boot device
4. Save and restart

---

## Installation Methods

### Method 1: Automated Installation (Recommended)

1. **Boot into Live Environment**
   - Select "Install SentinelX OS" from boot menu
   - Wait for live environment to load

2. **Launch Installer**
   ```bash
   sudo sx-install --guided
   ```

3. **Follow Installation Wizard**
   - Select language and keyboard layout
   - Configure network (if needed)
   - Partition disk (automatic or manual)
   - Set hostname and timezone
   - Create user account
   - Select packages to install

4. **Install Bootloader**
   - The installer will automatically configure GRUB2

5. **Complete Installation**
   - Remove installation media
   - Reboot into your new system

### Method 2: Manual Installation

1. **Partition Disk**
   ```bash
   # For UEFI systems
   parted /dev/sda mklabel gpt
   parted /dev/sda mkpart ESP fat32 1MiB 513MiB
   parted /dev/sda set 1 esp on
   parted /dev/sda mkpart primary btrfs 513MiB 100%
   ```

2. **Format Partitions**
   ```bash
   mkfs.fat -F32 /dev/sda1
   mkfs.btrfs -L SentinelX /dev/sda2
   ```

3. **Create Btrfs Subvolumes**
   ```bash
   mount /dev/sda2 /mnt
   btrfs subvolume create /mnt/@
   btrfs subvolume create /mnt/@home
   btrfs subvolume create /mnt/@var
   btrfs subvolume create /mnt/@snapshots
   umount /mnt
   ```

4. **Mount Partitions**
   ```bash
   mount -o subvol=@,compress=zstd /dev/sda2 /mnt
   mkdir -p /mnt/{boot/efi,home,var,.snapshots}
   mount /dev/sda1 /mnt/boot/efi
   mount -o subvol=@home,compress=zstd /dev/sda2 /mnt/home
   mount -o subvol=@var,compress=zstd /dev/sda2 /mnt/var
   mount -o subvol=@snapshots /dev/sda2 /mnt/.snapshots
   ```

5. **Install Base System**
   ```bash
   sx-install --target /mnt --base-system
   ```

6. **Configure System**
   ```bash
   # Chroot into new system
   arch-chroot /mnt
   
   # Set hostname
   echo "sentinelx" > /etc/hostname
   
   # Set timezone
   ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
   hwclock --systohc
   
   # Generate locale
   echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
   locale-gen
   echo "LANG=en_US.UTF-8" > /etc/locale.conf
   
   # Set root password
   passwd
   
   # Create user
   useradd -m -G wheel -s /bin/bash username
   passwd username
   
   # Enable sudo
   sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
   ```

7. **Install Bootloader**
   ```bash
   # Install GRUB
   pacman -S grub efibootmgr
   grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=SentinelX
   grub-mkconfig -o /boot/grub/grub.cfg
   ```

8. **Finish Installation**
   ```bash
   exit
   umount -R /mnt
   reboot
   ```

---

## Post-Installation

### 1. System Update
```bash
# Update package databases
sudo sx-pkg update

# Upgrade all packages
sudo sx-pkg upgrade
```

### 2. Install Desktop Environment
```bash
# Install SX Shell (Wayland)
sudo sx-pkg install sx-shell wayland

# Install display manager
sudo sx-pkg install sddm
sudo systemctl enable sddm
```

### 3. Configure Security
```bash
# Enable AppArmor
sudo systemctl enable --now apparmor

# Configure SELinux
sudo sx-config set security.selinux.enabled true
sudo sx-config set security.selinux.mode enforcing

# Enable firewall
sudo systemctl enable --now firewalld
sudo firewall-cmd --set-default-zone=public
```

### 4. Install Essential Software
```bash
# Browser
sudo sx-pkg install firefox

# Office suite
sudo sx-pkg install libreoffice

# Media player
sudo sx-pkg install vlc

# Development tools
sudo sx-pkg install base-devel git vim
```

### 5. Enable System Services
```bash
# Network time synchronization
sudo systemctl enable --now systemd-timesyncd

# Network management
sudo systemctl enable --now NetworkManager

# Bluetooth
sudo systemctl enable --now bluetooth

# Printer support
sudo systemctl enable --now cups
```

### 6. Configure Automatic Backups
```bash
# Create daily snapshot timer
sudo systemctl enable --now sx-backup.timer

# Or create snapshot manually
sudo sx-backup auto
```

---

## Troubleshooting

### Boot Issues

**Problem**: System doesn't boot after installation
```bash
# Boot from live USB
# Mount your system
sudo mount /dev/sda2 /mnt
sudo mount /dev/sda1 /mnt/boot/efi

# Chroot and reinstall bootloader
sudo arch-chroot /mnt
grub-install --target=x86_64-efi --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg
```

**Problem**: Black screen after GRUB
```bash
# Add kernel parameters in GRUB menu
# Press 'e' at GRUB menu and add:
nomodeset

# Or edit /etc/default/grub:
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nomodeset"
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### Package Management Issues

**Problem**: Package conflicts between Pacman and RPM
```bash
# Check package status
sx-pkg search package-name

# Resolve conflicts
sx-pkg resolve --conflicts

# Force reinstall
sx-pkg install --force package-name
```

### Network Issues

**Problem**: No network connection
```bash
# Check network interfaces
ip link show

# Restart NetworkManager
sudo systemctl restart NetworkManager

# Manual configuration
sudo nmcli device wifi connect "SSID" password "PASSWORD"
```

### Graphics Issues

**Problem**: Poor graphics performance
```bash
# Install proper graphics drivers

# For Intel:
sudo sx-pkg install xf86-video-intel vulkan-intel

# For AMD:
sudo sx-pkg install xf86-video-amdgpu vulkan-radeon

# For NVIDIA:
sudo sx-pkg install nvidia nvidia-utils
```

### Security Issues

**Problem**: AppArmor blocking applications
```bash
# Check AppArmor status
sudo aa-status

# Set profile to complain mode
sudo aa-complain /path/to/profile

# Disable specific profile
sudo aa-disable /path/to/profile
```

**Problem**: SELinux denying access
```bash
# Check SELinux status
getenforce

# View denials
sudo ausearch -m avc -ts recent

# Generate policy
sudo audit2allow -a -M mypolicy
sudo semodule -i mypolicy.pp
```

---

## Additional Resources

- **Official Documentation**: https://docs.sentinelx.org
- **Community Forum**: https://forum.sentinelx.org
- **Bug Reports**: https://github.com/sentinelx/sentinelx-os/issues
- **IRC Channel**: #sentinelx on irc.libera.chat

---

## Support

For additional help:
- Join our Discord: https://discord.gg/sentinelx
- Email: support@sentinelx.org
- Documentation: https://wiki.sentinelx.org

---

**Last Updated**: February 2026
**Version**: 1.0
