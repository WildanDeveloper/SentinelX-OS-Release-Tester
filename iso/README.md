# 💿 SentinelX ISO Builder

Tools for building bootable SentinelX OS ISO images.

## Overview

The ISO builder creates bootable installation media for SentinelX OS with:
- Live environment
- Graphical installer
- Recovery tools

## Quick Build

```bash
./build-iso.sh
```

## ISO Variants

| Variant | Size | Description |
|---------|------|-------------|
| Standard | ~2GB | Full desktop + apps |
| Minimal | ~800MB | Base system only |
| Server | ~1.2GB | No GUI, server tools |
