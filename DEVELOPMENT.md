# SentinelX OS Development Guide

## Table of Contents

1. [Getting Started](#getting-started)
2. [Development Workflow](#development-workflow)
3. [Building Components](#building-components)
4. [Testing](#testing)
5. [Contributing](#contributing)
6. [Troubleshooting](#troubleshooting)

---

## Getting Started

### Prerequisites

- Linux-based development environment (preferably Arch or Fedora)
- Git for version control
- sudo/root access for system-level operations
- At least 50GB free disk space
- Internet connection

### Clone Repository

```bash
git clone https://github.com/WildanDeveloper/SentinelX-OS.git
cd SentinelX-OS
```

### Project Structure

```
SentinelX-OS/
├── kernel/              # SX Custom Kernel 6.12
│   ├── build.sh        # Kernel build script
│   ├── configs/        # Kernel configurations
│   └── patches/        # Custom kernel patches
│
├── packages/            # Hybrid Package Manager (sx-pkg)
│   ├── sx-pkg          # Main package manager script
│   ├── sx-pkg.conf     # Configuration
│   └── setup.sh        # Package system setup
│
├── security/            # Security Layer
│   ├── apparmor/       # AppArmor profiles
│   ├── selinux/        # SELinux policies
│   └── hardening/      # System hardening scripts
│
├── installer/           # System Installer
│   ├── sx-install      # Main installer script
│   └── README.md       # Installation guide
│
├── iso/                 # ISO Builder
│   ├── build-iso.sh    # ISO creation script
│   └── configs/        # ISO configurations
│
├── desktop/             # Desktop Environment
│   └── sx-shell/       # SentinelX Shell setup
│
└── sx-test             # Testing framework
```

---

## Development Workflow

### 1. Create Feature Branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Make Changes

Edit files in the appropriate directory:

- **Kernel changes**: `kernel/`
- **Package manager**: `packages/`
- **Security policies**: `security/`
- **Installer**: `installer/`

### 3. Test Changes

```bash
# Run full test suite
./sx-test --all

# Or test specific component
./sx-test --kernel
./sx-test --packages
./sx-test --installer
```

### 4. Commit Changes

```bash
git add .
git commit -m "feat: add new feature description"
```

Use conventional commits:
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation
- `test:` for testing
- `refactor:` for code refactoring

### 5. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

---

## Building Components

### Build Custom Kernel

```bash
cd kernel/

# Check dependencies
./build.sh --deps

# Build kernel (without installing)
./build.sh

# Build and install
sudo ./build.sh --install

# Clean build artifacts
./build.sh --clean
```

**Build time**: ~30-60 minutes depending on hardware

### Build ISO

```bash
cd iso/

# Ensure kernel is built first
cd ../kernel && ./build.sh && cd ../iso

# Build ISO
sudo ./build-iso.sh

# Output: sentinelx-<date>.iso
```

### Test Package Manager

```bash
# Install sx-pkg to system
sudo cp packages/sx-pkg /usr/local/bin/
sudo chmod +x /usr/local/bin/sx-pkg

# Test basic commands
sx-pkg status
sx-pkg search firefox
sx-pkg list
```

---

## Testing

### Automated Testing

```bash
# Make test script executable
chmod +x sx-test

# Run all tests
./sx-test --all

# Run specific test suites
./sx-test --kernel       # Test kernel build system
./sx-test --packages     # Test package manager
./sx-test --security     # Test security configs
./sx-test --installer    # Test installer
./sx-test --docs         # Test documentation
./sx-test --quality      # Test code quality

# Fast mode (skip slow tests)
./sx-test --fast
```

### Manual Testing

#### Test Kernel Build
```bash
cd kernel/
./build.sh --deps  # Should install missing dependencies
./build.sh         # Should build without errors
```

#### Test Package Manager
```bash
# Test package detection
packages/sx-pkg status

# Test search (read-only)
packages/sx-pkg search vim

# Test in VM before production
```

#### Test Installer
```bash
# ONLY test in VM or spare machine!
# Installer WIPES disks!

# Boot from live USB
# Run installer in test mode (if available)
sudo installer/sx-install
```

### Virtual Machine Testing

Recommended for installer testing:

1. **VirtualBox/VMware**: Create new VM
   - Type: Linux, Arch Linux 64-bit
   - RAM: 4GB minimum
   - Disk: 30GB minimum
   - Network: NAT or Bridged

2. **QEMU/KVM**:
   ```bash
   qemu-system-x86_64 \
     -m 4G \
     -smp 4 \
     -drive file=test-disk.qcow2,if=virtio \
     -cdrom sentinelx.iso \
     -boot d
   ```

---

## Contributing

### Code Standards

- **Shell scripts**: Use `shellcheck` for linting
- **Error handling**: Always use `set -euo pipefail`
- **Comments**: Document complex logic
- **Functions**: One function, one purpose
- **Variables**: Use descriptive names

### Before Submitting PR

1. **Run tests**:
   ```bash
   ./sx-test --all
   ```

2. **Check code quality**:
   ```bash
   shellcheck kernel/build.sh
   shellcheck packages/sx-pkg
   shellcheck installer/sx-install
   ```

3. **Update documentation**:
   - Update README if adding features
   - Add comments to complex code
   - Update ROADMAP for major features

4. **Test in VM**:
   - Especially for installer changes
   - Test both UEFI and BIOS modes

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation
- [ ] Performance improvement

## Testing
- [ ] Ran full test suite (`./sx-test --all`)
- [ ] Tested in VM
- [ ] Tested on physical hardware

## Screenshots (if UI changes)
```

---

## Troubleshooting

### Kernel Build Issues

**Problem**: Missing dependencies

```bash
# Install build dependencies
kernel/build.sh --deps

# Or manually:
# Arch-based
sudo pacman -S base-devel bc bison flex

# Red Hat-based
sudo dnf groupinstall "Development Tools"
sudo dnf install bc bison flex
```

**Problem**: Build fails with "No space left"

```bash
# Clean build directory
kernel/build.sh --clean

# Check disk space
df -h
```

### Package Manager Issues

**Problem**: sx-pkg can't detect repositories

```bash
# Check if package managers are installed
command -v pacman
command -v dnf

# Install missing package manager
# (Note: Both are needed for hybrid functionality)
```

**Problem**: Permission denied

```bash
# sx-pkg needs root for system operations
sudo sx-pkg install <package>
```

### Installer Issues

**Problem**: Installer fails to partition disk

```bash
# Check if disk is busy
lsblk
sudo umount /dev/sdX*

# Wipe disk manually
sudo wipefs -af /dev/sdX
sudo sgdisk --zap-all /dev/sdX
```

**Problem**: No internet during installation

```bash
# Test connectivity
ping -c 3 8.8.8.8

# WiFi setup
iwctl
station wlan0 connect "SSID"
```

### Testing Framework Issues

**Problem**: Tests fail with permission errors

```bash
# Some tests may need root
sudo ./sx-test --all
```

**Problem**: Tests report missing files

```bash
# Ensure you're in project root
cd /path/to/SentinelX-OS
./sx-test --all
```

---

## Development Tips

### Fast Iteration

```bash
# Use VM snapshots for installer testing
# Take snapshot before running installer
# Restore after testing

# Use separate build directory for kernel
export BUILD_DIR=/mnt/fast-ssd/kernel-build
```

### Debugging Scripts

```bash
# Enable bash debug mode
bash -x kernel/build.sh

# Add verbose logging
set -x  # At top of script
```

### Performance Profiling

```bash
# Time script execution
time ./kernel/build.sh

# Profile with perf (if available)
perf record -g ./kernel/build.sh
perf report
```

---

## Resources

- **Arch Wiki**: https://wiki.archlinux.org
- **Red Hat Docs**: https://access.redhat.com/documentation
- **Kernel.org**: https://kernel.org
- **Btrfs Wiki**: https://btrfs.wiki.kernel.org

---

## Getting Help

- **Issues**: [GitHub Issues](https://github.com/WildanDeveloper/SentinelX-OS/issues)
- **Discussions**: [GitHub Discussions](https://github.com/WildanDeveloper/SentinelX-OS/discussions)
- **Email**: wildan@sentinelx.org

---

## License

SentinelX OS is licensed under GPL v3.0.  
See [LICENSE](LICENSE) file for details.

---

**Happy Hacking!** 🚀
