# SentinelX OS - Developer API Documentation

## Overview

This document provides comprehensive API documentation for developing applications and tools for SentinelX OS.

---

## Table of Contents

1. [System APIs](#system-apis)
2. [Package Management API](#package-management-api)
3. [Configuration API](#configuration-api)
4. [Security API](#security-api)
5. [Backup API](#backup-api)
6. [Desktop Integration](#desktop-integration)
7. [Building Extensions](#building-extensions)

---

## System APIs

### SentinelX System Library

```python
from sentinelx import system

# Get system information
info = system.get_info()
print(f"Hostname: {info.hostname}")
print(f"Kernel: {info.kernel_version}")
print(f"Uptime: {info.uptime}")

# Get hardware information
hw = system.get_hardware()
print(f"CPU: {hw.cpu.model}")
print(f"RAM: {hw.memory.total_gb} GB")
```

### System Configuration

```python
from sentinelx.config import SystemConfig

config = SystemConfig()

# Read configuration
hostname = config.get('system.hostname')
timezone = config.get('system.timezone')

# Update configuration
config.set('system.hostname', 'myserver')
config.save()
config.apply()
```

### System Services

```python
from sentinelx.services import ServiceManager

sm = ServiceManager()

# Check service status
status = sm.status('NetworkManager')

# Control services
sm.start('httpd')
sm.stop('httpd')
sm.restart('httpd')
sm.enable('httpd')
```

---

## Package Management API

### Python API

```python
from sentinelx.packages import PackageManager

pm = PackageManager()

# Search packages
results = pm.search('firefox')
for pkg in results:
    print(f"{pkg.name} - {pkg.version}")

# Install package
pm.install('firefox', source='auto')  # auto-detect best source
pm.install('vim', source='pacman')    # specific source
pm.install('httpd', source='rpm')

# Remove package
pm.remove('firefox')

# Update packages
pm.update()  # Update database
pm.upgrade()  # Upgrade all packages

# Get package information
info = pm.info('firefox')
print(info.description)
print(info.dependencies)
```

### Command-line Integration

```bash
#!/bin/bash
# Example: Check if package is installed

if sx-pkg list --installed | grep -q "firefox"; then
    echo "Firefox is installed"
else
    echo "Firefox is not installed"
    sudo sx-pkg install firefox
fi
```

### Package Hooks

Create package installation hooks:

```python
# /etc/sentinelx/package-hooks.d/my-hook.py

def post_install(package_name, package_info):
    """Called after package installation"""
    if package_name == 'nginx':
        # Auto-configure nginx
        configure_nginx()

def pre_remove(package_name, package_info):
    """Called before package removal"""
    if package_name == 'mysql':
        # Backup database
        backup_database()
```

---

## Configuration API

### Configuration Management

```python
from sentinelx.config import Config

# Load configuration
config = Config('/etc/sentinelx/myapp.conf')

# Read values
db_host = config.get('database.host', default='localhost')
db_port = config.get('database.port', default=5432)

# Write values
config.set('database.host', 'db.example.com')
config.set('database.port', 5432)

# Save configuration
config.save()

# Watch for changes
def on_config_change(key, old_value, new_value):
    print(f"Config changed: {key} = {new_value}")

config.watch('database.host', on_config_change)
```

### System-wide Configuration

```python
from sentinelx.config import SystemConfig

config = SystemConfig()

# Get nested values
security_enabled = config.get('security.apparmor.enabled')

# Update nested values
config.set('security.firewall.default_zone', 'public')

# Apply system configuration
config.apply_system()
config.apply_security()
config.apply_performance()
```

---

## Security API

### AppArmor Integration

```python
from sentinelx.security import AppArmor

aa = AppArmor()

# Load profile
aa.load_profile('/etc/apparmor.d/usr.bin.myapp')

# Set profile mode
aa.enforce('/etc/apparmor.d/usr.bin.myapp')
aa.complain('/etc/apparmor.d/usr.bin.myapp')

# Check profile status
status = aa.status('usr.bin.myapp')
print(f"Mode: {status.mode}")
```

### SELinux Integration

```python
from sentinelx.security import SELinux

se = SELinux()

# Get SELinux mode
mode = se.get_mode()  # enforcing, permissive, disabled

# Set file context
se.set_context('/var/www/html/index.html', 'httpd_sys_content_t')

# Check boolean
httpd_can_network = se.get_boolean('httpd_can_network_connect')

# Set boolean
se.set_boolean('httpd_can_network_connect', True)
```

### Firewall Integration

```python
from sentinelx.security import Firewall

fw = Firewall()

# Add service
fw.add_service('http')
fw.add_service('https')

# Add port
fw.add_port(8080, 'tcp')

# Add rich rule
fw.add_rich_rule('rule family="ipv4" source address="192.168.1.0/24" accept')

# Reload firewall
fw.reload()
```

---

## Backup API

### Snapshot Management

```python
from sentinelx.backup import SnapshotManager

sm = SnapshotManager()

# Create snapshot
snapshot = sm.create_snapshot('before-update')
print(f"Created: {snapshot.name}")

# List snapshots
for snap in sm.list_snapshots():
    print(f"{snap.name} - {snap.timestamp}")

# Rollback
sm.rollback('snapshot-name')

# Delete snapshot
sm.delete_snapshot('old-snapshot')
```

### Backup Operations

```python
from sentinelx.backup import BackupManager

bm = BackupManager()

# Create full backup
backup = bm.create_backup('/backup/location')
print(f"Backup created: {backup.path}")

# Restore from backup
bm.restore_backup('/backup/location/backup.tar.gz')

# Schedule automatic backups
bm.schedule_backup('daily', time='02:00')
```

---

## Desktop Integration

### Application Launcher

Create a `.desktop` file:

```ini
[Desktop Entry]
Name=My Application
Comment=My awesome app
Exec=/usr/bin/myapp
Icon=/usr/share/icons/myapp.png
Terminal=false
Type=Application
Categories=Utility;
```

Place in `/usr/share/applications/` or `~/.local/share/applications/`

### System Tray Integration

```python
from sentinelx.desktop import SystemTray

tray = SystemTray()

# Add tray icon
tray.set_icon('/usr/share/icons/myapp.png')
tray.set_tooltip('My Application')

# Add menu items
menu = tray.create_menu()
menu.add_item('Show Window', show_window)
menu.add_item('Settings', show_settings)
menu.add_separator()
menu.add_item('Quit', quit_app)

tray.show()
```

### Notifications

```python
from sentinelx.desktop import Notifications

notif = Notifications()

# Send notification
notif.send(
    title='Update Available',
    message='A new version is available',
    icon='software-update-available',
    urgency='normal',  # low, normal, critical
    timeout=5000  # milliseconds
)

# With action buttons
def on_update_click():
    install_update()

notif.send(
    title='Update Available',
    message='Click to install',
    actions=[
        ('update', 'Update Now', on_update_click),
        ('cancel', 'Later', None)
    ]
)
```

---

## Building Extensions

### Extension Structure

```
myextension/
├── extension.json
├── main.py
├── config.yaml
└── resources/
    ├── icon.png
    └── data.json
```

### Extension Manifest

`extension.json`:
```json
{
  "name": "My Extension",
  "version": "1.0.0",
  "description": "Does something cool",
  "author": "Your Name",
  "entry_point": "main.py",
  "dependencies": [
    "python-requests",
    "python-yaml"
  ],
  "permissions": [
    "network",
    "filesystem",
    "system"
  ]
}
```

### Extension API

```python
# main.py
from sentinelx.extensions import Extension

class MyExtension(Extension):
    def on_load(self):
        """Called when extension is loaded"""
        self.config = self.load_config('config.yaml')
        self.register_command('mycommand', self.handle_command)
    
    def handle_command(self, args):
        """Handle custom command"""
        print(f"Command executed with args: {args}")
    
    def on_unload(self):
        """Called when extension is unloaded"""
        self.cleanup()

# Register extension
extension = MyExtension()
```

### Installing Extensions

```bash
# Install from directory
sx-ext install /path/to/extension

# Install from archive
sx-ext install extension.tar.gz

# List installed extensions
sx-ext list

# Enable/disable extension
sx-ext enable myextension
sx-ext disable myextension

# Remove extension
sx-ext remove myextension
```

---

## Example Applications

### System Monitor Widget

```python
#!/usr/bin/env python3
from sentinelx import system
from sentinelx.desktop import Widget
import time

class SystemMonitorWidget(Widget):
    def __init__(self):
        super().__init__()
        self.set_size(200, 100)
        self.update()
    
    def update(self):
        cpu = system.get_cpu_usage()
        mem = system.get_memory_usage()
        
        text = f"CPU: {cpu}%\nRAM: {mem}%"
        self.set_text(text)
        
        # Update every second
        self.schedule_update(1000, self.update)

if __name__ == '__main__':
    widget = SystemMonitorWidget()
    widget.show()
```

### Backup Script

```python
#!/usr/bin/env python3
from sentinelx.backup import SnapshotManager
from sentinelx.desktop import Notifications
import sys

def create_backup():
    notif = Notifications()
    sm = SnapshotManager()
    
    try:
        notif.send('Creating backup...', 'Please wait')
        snapshot = sm.create_snapshot('auto-backup')
        notif.send(
            'Backup Complete',
            f'Snapshot created: {snapshot.name}',
            urgency='low'
        )
        return 0
    except Exception as e:
        notif.send(
            'Backup Failed',
            str(e),
            urgency='critical'
        )
        return 1

if __name__ == '__main__':
    sys.exit(create_backup())
```

---

## Best Practices

### Error Handling

Always use proper error handling:

```python
from sentinelx.exceptions import SentinelXError

try:
    result = dangerous_operation()
except SentinelXError as e:
    log_error(f"Operation failed: {e}")
    notify_user(f"Error: {e}")
except Exception as e:
    log_error(f"Unexpected error: {e}")
    raise
```

### Logging

Use the SentinelX logging system:

```python
from sentinelx.logging import get_logger

logger = get_logger('myapp')

logger.debug('Debug message')
logger.info('Info message')
logger.warning('Warning message')
logger.error('Error message')
logger.critical('Critical message')
```

### Configuration

Store configuration in standard locations:

- System-wide: `/etc/sentinelx/myapp/`
- User-specific: `~/.config/myapp/`
- Temporary: `/tmp/myapp/`

### Permissions

Request only necessary permissions:

```json
{
  "permissions": [
    "filesystem:read",
    "filesystem:write:/var/myapp",
    "network:http",
    "system:info"
  ]
}
```

---

## API Reference

### Complete API Documentation

For complete API reference, visit:
https://docs.sentinelx.org/api/

### Python Package

Install the SentinelX Python package:

```bash
pip install sentinelx-api
```

### Language Bindings

- **Python**: `sentinelx-api`
- **C/C++**: `libsentinelx`
- **Rust**: `sentinelx-rs`
- **Go**: `go-sentinelx`

---

## Support

For development support:
- **Documentation**: https://docs.sentinelx.org
- **API Reference**: https://api.sentinelx.org
- **Developer Forum**: https://dev.sentinelx.org
- **Discord**: #dev channel on https://discord.gg/sentinelx

---

**SentinelX OS Developer Documentation**
**Version**: 1.0
**Last Updated**: February 2026
