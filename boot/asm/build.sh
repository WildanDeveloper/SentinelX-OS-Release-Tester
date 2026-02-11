#!/bin/bash
#
# Build script for SentinelX boot assembly code
#

set -e

NASM=$(command -v nasm || echo "")
LD=$(command -v ld || echo "")

if [ -z "$NASM" ]; then
    echo "Error: nasm not found. Install with: sudo pacman -S nasm"
    exit 1
fi

if [ -z "$LD" ]; then
    echo "Error: ld not found. Install binutils."
    exit 1
fi

echo "Building SentinelX fast boot stub..."

# Assemble
nasm -f elf64 fast_boot.asm -o fast_boot.o

echo "✓ Assembly complete: fast_boot.o"

# Link (create flat binary for boot sector if needed)
# ld -n -T boot.ld fast_boot.o -o fast_boot.bin

echo "✓ Build complete"
echo ""
echo "Note: This is a boot stub. Integration with bootloader required."
