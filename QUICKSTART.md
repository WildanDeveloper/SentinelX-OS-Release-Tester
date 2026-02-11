# 🚀 SentinelX OS - Quick Start Guide

Welcome to **SentinelX OS**! This guide will help you get started in 5 minutes.

---

## 📋 What is SentinelX OS?

SentinelX OS is a **hybrid Linux distribution** that combines:
- **Arch Linux** — Rolling release, cutting-edge packages
- **Red Hat Enterprise Linux** — Enterprise stability and security

**Result**: A fast, stable, and secure operating system for developers and power users.

---

## ⚡ Quick Installation (For End Users)

### Option 1: Download Pre-built ISO (Coming Soon)

1. Download ISO from [releases page](https://github.com/WildanDeveloper/SentinelX-OS/releases)
2. Flash to USB drive:
   ```bash
   sudo dd if=sentinelx.iso of=/dev/sdX bs=4M status=progress
   ```
3. Boot from USB and follow installer prompts

### Option 2: Try in Virtual Machine

**VirtualBox:**
1. Create new VM: Linux → Arch Linux (64-bit)
2. RAM: 4GB, Disk: 30GB
3. Attach ISO and boot
4. Run installer: `sudo sx-install`

**QEMU:**
```bash
qemu-system-x86_64 -m 4G -smp 4 \
  -drive file=disk.qcow2,if=virtio \
  -cdrom sentinelx.iso -boot d
```

---

## 🛠️ For Developers

### 1. Clone Repository

```bash
git clone https://github.com/WildanDeveloper/SentinelX-OS.git
cd SentinelX-OS
```

### 2. Run Tests

```bash
chmod +x sx-test
./sx-test --all
```

### 3. Build Custom Kernel

```bash
cd kernel/
./build.sh --deps      # Install dependencies
./build.sh             # Build kernel (~30-60 min)
sudo ./build.sh --install  # Install to system
```

### 4. Try Package Manager

```bash
# Install sx-pkg
sudo cp packages/sx-pkg /usr/local/bin/
sudo chmod +x /usr/local/bin/sx-pkg

# Test commands
sx-pkg status
sx-pkg search firefox
sx-pkg install neovim
```

### 5. Build ISO

```bash
cd iso/
sudo ./build-iso.sh
# Output: sentinelx-YYYYMMDD.iso
```

---

## 📦 Key Components

| Component | Description | Location |
|-----------|-------------|----------|
| **SX Kernel** | Custom Linux 6.12 kernel | `kernel/` |
| **sx-pkg** | Hybrid package manager (Arch + Red Hat) | `packages/` |
| **sx-install** | System installer | `installer/` |
| **sx-shell** | Desktop environment setup | `desktop/` |
| **sx-test** | Testing framework | `sx-test` |
| **Security** | AppArmor + SELinux configs | `security/` |

---

## 🎯 Common Tasks

### Install Desktop Environment

```bash
# After installing SentinelX OS
cd /opt/sentinelx/desktop/sx-shell
./sx-shell-setup

# Choose: GNOME, KDE, XFCE, or i3wm
```

### Update System

```bash
sx-pkg update       # Update all packages
sx-pkg autoremove   # Remove orphaned packages
sx-pkg clean        # Clean cache
```

### Create System Snapshot (Btrfs)

```bash
sudo btrfs subvolume snapshot / /.snapshots/backup-$(date +%Y%m%d)
```

### Rollback System

```bash
# Boot into live USB
sudo mount /dev/sdX3 /mnt
sudo mv /mnt/@ /mnt/@_old
sudo btrfs subvolume snapshot /mnt/@snapshots/backup-20260210 /mnt/@
sudo umount /mnt
reboot
```

---

## 🐛 Troubleshooting

### Build Fails

```bash
# Check logs
cat kernel/logs/build-*.log

# Clean and retry
kernel/build.sh --clean
kernel/build.sh
```

### Package Manager Issues

```bash
# Check status
sx-pkg status

# Check if both pacman and dnf are available
command -v pacman
command -v dnf
```

### Network Not Working

```bash
# Enable NetworkManager
sudo systemctl enable --now NetworkManager

# WiFi
nmcli device wifi list
nmcli device wifi connect "SSID" password "PASSWORD"
```

---

## 📚 Documentation

- **Full Documentation**: [DEVELOPMENT.md](DEVELOPMENT.md)
- **Installation Guide**: [installer/README.md](installer/README.md)
- **Contributing**: [CONTRIBUTING.md](CONTRIBUTING.md)
- **Roadmap**: [ROADMAP.md](ROADMAP.md)

---

## 🤝 Contributing

We welcome contributions! Here's how:

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/my-feature`
3. **Make** your changes and **test**: `./sx-test --all`
4. **Commit**: `git commit -m "feat: add my feature"`
5. **Push**: `git push origin feature/my-feature`
6. **Open** a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

---

## 🌟 Features

✅ **Rolling release** — Always up-to-date  
✅ **Hybrid packages** — Arch + Red Hat repos  
✅ **Custom kernel** — Optimized for performance  
✅ **Dual security** — AppArmor + SELinux  
✅ **Atomic updates** — Btrfs snapshots  
✅ **Container-first** — Podman, Docker ready  

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/WildanDeveloper/SentinelX-OS/issues)
- **Discussions**: [GitHub Discussions](https://github.com/WildanDeveloper/SentinelX-OS/discussions)
- **Wiki**: [GitHub Wiki](https://github.com/WildanDeveloper/SentinelX-OS/wiki)

---

## 📄 License

SentinelX OS is licensed under **GPL v3.0**.  
See [LICENSE](LICENSE) for details.

---

## 🎉 Welcome to SentinelX!

**Built for Performance. Designed for Control.**

Start building something amazing today! 🚀

---

## Next Steps

1. ⭐ **Star** this repository
2. 📖 Read [DEVELOPMENT.md](DEVELOPMENT.md)
3. 🔧 Build your first component
4. 🤝 Join our community
5. 🚀 Deploy SentinelX!
