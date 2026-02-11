# SentinelX OS - Makefile
# Build automation for the complete system

.PHONY: all build install clean test help kernel packages security desktop iso docs

# Default target
all: help

# Build everything
build: kernel packages security desktop docs
	@echo "✓ Build completed successfully"

# Build custom kernel
kernel:
	@echo "Building SX Custom Kernel..."
	@cd kernel && bash build.sh
	@echo "✓ Kernel build completed"

# Setup package management system
packages:
	@echo "Setting up package management..."
	@cd packages && bash setup.sh
	@chmod +x packages/sx-pkg
	@echo "✓ Package system configured"

# Configure security layers
security:
	@echo "Configuring security layers..."
	@if [ -d security/hardening ]; then cd security/hardening && bash setup.sh; fi
	@echo "✓ Security configured"

# Build desktop environment
desktop:
	@echo "Building desktop environment..."
	@chmod +x desktop/sx-shell/sx-compositor
	@echo "✓ Desktop environment ready"

# Build ISO image
iso:
	@echo "Building bootable ISO..."
	@cd iso && bash build-iso.sh
	@echo "✓ ISO build completed"

# Generate documentation
docs:
	@echo "Generating documentation..."
	@mkdir -p build/docs
	@cp -r docs/* build/docs/
	@echo "✓ Documentation generated"

# Install to system
install: build
	@echo "Installing SentinelX OS components..."
	@install -Dm755 tools/sx-backup /usr/bin/sx-backup
	@install -Dm755 tools/sx-config /usr/bin/sx-config
	@install -Dm755 tools/sx-monitor.py /usr/bin/sx-monitor
	@install -Dm755 tools/sx-test /usr/bin/sx-test
	@install -Dm755 packages/sx-pkg /usr/bin/sx-pkg
	@install -Dm755 desktop/sx-shell/sx-compositor /usr/bin/sx-compositor
	@install -Dm644 systemd/sx-backup.service /usr/lib/systemd/system/sx-backup.service
	@install -Dm644 systemd/sx-backup.timer /usr/lib/systemd/system/sx-backup.timer
	@install -Dm644 systemd/sx-monitor.service /usr/lib/systemd/system/sx-monitor.service
	@mkdir -p /etc/sentinelx
	@mkdir -p /var/lib/sentinelx
	@mkdir -p /var/log/sentinelx
	@echo "✓ Installation completed"

# Install kernel
install-kernel:
	@echo "Installing kernel..."
	@cd kernel && sudo bash install.sh
	@echo "✓ Kernel installed"

# Run tests
test:
	@echo "Running system tests..."
	@chmod +x tools/sx-test
	@tools/sx-test
	@echo "✓ Tests completed"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf build/
	@rm -rf kernel/logs/*
	@rm -rf packages/cache/*
	@rm -rf iso/output/*
	@find . -type f -name "*.pyc" -delete
	@find . -type d -name "__pycache__" -delete
	@echo "✓ Cleanup completed"

# Deep clean (including downloads)
distclean: clean
	@echo "Deep cleaning..."
	@rm -rf kernel/linux-*.tar.xz
	@rm -rf packages/db/*
	@echo "✓ Deep cleanup completed"

# Check dependencies
deps:
	@echo "Checking build dependencies..."
	@command -v gcc >/dev/null 2>&1 || echo "Missing: gcc"
	@command -v make >/dev/null 2>&1 || echo "Missing: make"
	@command -v python3 >/dev/null 2>&1 || echo "Missing: python3"
	@command -v git >/dev/null 2>&1 || echo "Missing: git"
	@command -v bison >/dev/null 2>&1 || echo "Missing: bison"
	@command -v flex >/dev/null 2>&1 || echo "Missing: flex"
	@echo "✓ Dependency check completed"

# Format code
format:
	@echo "Formatting code..."
	@find . -name "*.py" -exec python3 -m black {} +
	@find . -name "*.sh" -exec shfmt -w {} +
	@echo "✓ Code formatted"

# Lint code
lint:
	@echo "Linting code..."
	@find . -name "*.py" -exec pylint {} +
	@find . -name "*.sh" -exec shellcheck {} +
	@echo "✓ Linting completed"

# Generate release
release: clean build test
	@echo "Creating release package..."
	@mkdir -p build/release
	@tar czf build/release/sentinelx-os-$$(date +%Y%m%d).tar.gz \
		--exclude='.git' \
		--exclude='build' \
		--exclude='*.pyc' \
		--exclude='__pycache__' \
		.
	@echo "✓ Release package created"

# Development setup
dev-setup:
	@echo "Setting up development environment..."
	@pip install --user black pylint pytest
	@echo "✓ Development environment ready"

# Run in development mode
dev-run:
	@echo "Running in development mode..."
	@export SENTINELX_DEV=1
	@bash build-all.sh

# Create package
package: build
	@echo "Creating distribution package..."
	@mkdir -p build/package/DEBIAN
	@cat > build/package/DEBIAN/control << EOF
	Package: sentinelx-os
	Version: 1.0.0
	Section: base
	Priority: optional
	Architecture: amd64
	Maintainer: WildanDev <wildan@sentinelx.org>
	Description: SentinelX OS - Hybrid Linux Distribution
	 A next-generation hybrid Linux operating system combining
	 Arch Linux and Red Hat Enterprise Linux.
	EOF
	@mkdir -p build/package/usr/bin
	@cp tools/* build/package/usr/bin/
	@dpkg-deb --build build/package
	@echo "✓ Package created"

# Show system information
info:
	@echo "SentinelX OS Build System"
	@echo "========================="
	@echo "Version:     1.0.0"
	@echo "Build Date:  $$(date)"
	@echo "Kernel:      6.12-sx"
	@echo "Build Dir:   $$(pwd)/build"
	@echo ""

# Help message
help:
	@echo ""
	@echo "  ██████ ▓█████  ███▄    █ ▓█████▓ ██▓ ███▄    █ ▓█████  ██▓    ▒██   ██▒"
	@echo ""
	@echo "  SentinelX OS - Build System"
	@echo ""
	@echo "Available targets:"
	@echo ""
	@echo "  make build          - Build all components"
	@echo "  make kernel         - Build custom kernel"
	@echo "  make packages       - Setup package management"
	@echo "  make security       - Configure security layers"
	@echo "  make desktop        - Build desktop environment"
	@echo "  make iso            - Build bootable ISO"
	@echo "  make docs           - Generate documentation"
	@echo ""
	@echo "  make install        - Install to system"
	@echo "  make install-kernel - Install kernel only"
	@echo ""
	@echo "  make test           - Run tests"
	@echo "  make clean          - Clean build artifacts"
	@echo "  make distclean      - Deep clean"
	@echo ""
	@echo "  make deps           - Check dependencies"
	@echo "  make format         - Format code"
	@echo "  make lint           - Lint code"
	@echo ""
	@echo "  make release        - Create release package"
	@echo "  make dev-setup      - Setup development environment"
	@echo "  make dev-run        - Run in development mode"
	@echo ""
	@echo "  make help           - Show this help message"
	@echo "  make info           - Show system information"
	@echo ""
