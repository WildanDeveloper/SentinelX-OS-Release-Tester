#!/bin/bash
#
# SentinelX OS — ISO Builder
# Copyright (C) 2026 WildanDev
# License: GPL v3
#
# Builds a bootable hybrid ISO image for SentinelX OS.
# Supports three variants: standard, minimal, server.
#
# Usage:
#   sudo ./build-iso.sh [OPTIONS]
#
#   --variant <n>     standard | minimal | server  (default: standard)
#   --output  <dir>      Output directory             (default: ./output)
#   --work    <dir>      Scratch directory            (default: ./work)
#   --kernel  <path>     Path to compiled vmlinuz-*-sx
#   --rootfs  <path>     Path to pre-built rootfs dir (skips bootstrap)
#   --no-clean           Keep work directory after build
#   --sign               Sign ISO with GPG key
#   --gpg-key <id>       GPG key ID for signing
#   --check              Verify build environment only, do not build
#   --help               Show this help
#
set -euo pipefail

# ─────────────────────────────────────────────
#  VERSION & IDENTITY
# ─────────────────────────────────────────────
readonly SX_VERSION="1.0.0"
readonly SX_CODENAME="Sentinel"
readonly SX_ARCH="x86_64"
readonly SX_LABEL="SENTINELX_OS"
readonly SX_PUBLISHER="SentinelX Project <build@sentinelx.os>"
readonly SX_URL="https://github.com/WildanDeveloper/SentinelX-OS"
readonly BUILD_DATE=$(date +%Y%m%d)
readonly BUILD_TS=$(date '+%Y-%m-%d %H:%M:%S')

# ─────────────────────────────────────────────
#  DEFAULTS (overridden by CLI args)
# ─────────────────────────────────────────────
VARIANT="standard"
WORK_DIR="./work"
OUTPUT_DIR="./output"
KERNEL_PATH=""
ROOTFS_PATH=""
CLEAN=1
SIGN=0
GPG_KEY=""
CHECK_ONLY=0
LOG_DIR="./logs"

# Derived paths (set after arg parsing)
ROOTFS_DIR=""
ISO_STAGING=""
EFI_DIR=""
SQUASHFS_IMG=""
ISO_FILE=""
LOG_FILE=""
ISO_NAME=""

# ─────────────────────────────────────────────
#  COLORS
# ─────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ─────────────────────────────────────────────
#  PACKAGE LISTS PER VARIANT
# ─────────────────────────────────────────────

PACKAGES_BASE=(
    base base-devel linux-firmware linux-headers
    grub efibootmgr os-prober
    btrfs-progs e2fsprogs xfsprogs dosfstools ntfs-3g
    networkmanager iwd wireless_tools net-tools curl wget rsync
    sudo polkit systemd systemd-resolvconf dbus
    apparmor audit gnupg
    bash zsh vim nano htop tree file which less man-db
    tar gzip bzip2 xz zstd
)

PACKAGES_STANDARD=(
    "${PACKAGES_BASE[@]}"
    wayland xwayland mesa libdrm vulkan-icd-loader
    pipewire pipewire-pulse pipewire-alsa wireplumber
    ttf-dejavu ttf-liberation noto-fonts
    firefox thunar mousepad eog cups ghostscript
    bluez bluez-utils orca at-spi2-core
)

PACKAGES_MINIMAL=(
    "${PACKAGES_BASE[@]}"
    tmux openssh
)

PACKAGES_SERVER=(
    "${PACKAGES_BASE[@]}"
    openssh nginx mariadb redis
    podman buildah skopeo
    prometheus-node-exporter
    firewalld nftables
    selinux-policy selinux-policy-targeted policycoreutils
)

# ─────────────────────────────────────────────
#  LOGGING
# ─────────────────────────────────────────────
_setup_log() {
    mkdir -p "$LOG_DIR"
    LOG_FILE="${LOG_DIR}/build-${VARIANT}-${BUILD_DATE}.log"
    exec > >(tee -a "$LOG_FILE") 2>&1
}

log_info()  { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗] $1${NC}" >&2; }
log_step()  { echo -e "\n${CYAN}${BOLD}══════════════════════════════════════════${NC}";
              echo -e "${CYAN}${BOLD}  $1${NC}";
              echo -e "${CYAN}${BOLD}══════════════════════════════════════════${NC}"; }
log_sub()   { echo -e "  ${BLUE}→${NC} $1"; }
log_dim()   { echo -e "  ${DIM}$1${NC}"; }

# ─────────────────────────────────────────────
#  BANNER
# ─────────────────────────────────────────────
print_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║         SentinelX OS — ISO Build System              ║"
    echo "║                   v${SX_VERSION} · ${SX_CODENAME}                    ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${BOLD}Variant :${NC}  $VARIANT"
    echo -e "  ${BOLD}Arch    :${NC}  $SX_ARCH"
    echo -e "  ${BOLD}Date    :${NC}  $BUILD_TS"
    echo -e "  ${BOLD}Work    :${NC}  $WORK_DIR"
    echo -e "  ${BOLD}Output  :${NC}  $OUTPUT_DIR"
    echo ""
}

show_help() {
    echo -e "${BOLD}USAGE:${NC}  sudo ./build-iso.sh [OPTIONS]"
    echo ""
    echo -e "${BOLD}OPTIONS:${NC}"
    echo "  --variant  <n>    standard | minimal | server  (default: standard)"
    echo "  --output   <dir>     Output directory             (default: ./output)"
    echo "  --work     <dir>     Scratch build directory      (default: ./work)"
    echo "  --kernel   <path>    Path to compiled vmlinuz-*-sx"
    echo "  --rootfs   <path>    Use existing rootfs dir (skip bootstrap)"
    echo "  --no-clean           Keep work directory after build"
    echo "  --sign               Sign the ISO with GPG"
    echo "  --gpg-key  <id>      GPG key fingerprint for signing"
    echo "  --check              Verify build environment only"
    echo "  --help               Show this help"
    echo ""
    echo -e "${BOLD}VARIANTS:${NC}"
    printf "  %-12s %s\n" "standard" "Full desktop environment (~2GB)"
    printf "  %-12s %s\n" "minimal"  "Base system only (~800MB)"
    printf "  %-12s %s\n" "server"   "Headless server with containers (~1.2GB)"
    echo ""
    echo -e "${BOLD}EXAMPLES:${NC}"
    echo "  sudo ./build-iso.sh"
    echo "  sudo ./build-iso.sh --variant server --output /tmp/iso"
    echo "  sudo ./build-iso.sh --variant minimal --no-clean"
    echo "  sudo ./build-iso.sh --kernel ../kernel/build/linux-6.12/arch/x86/boot/bzImage"
}

# ─────────────────────────────────────────────
#  ARGUMENT PARSING
# ─────────────────────────────────────────────
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --variant)  VARIANT="${2:-standard}";  shift 2 ;;
            --output)   OUTPUT_DIR="${2:-.}";       shift 2 ;;
            --work)     WORK_DIR="${2:-.}";         shift 2 ;;
            --kernel)   KERNEL_PATH="${2:-}";       shift 2 ;;
            --rootfs)   ROOTFS_PATH="${2:-}";       shift 2 ;;
            --no-clean) CLEAN=0;                    shift   ;;
            --sign)     SIGN=1;                     shift   ;;
            --gpg-key)  GPG_KEY="${2:-}";           shift 2 ;;
            --check)    CHECK_ONLY=1;               shift   ;;
            --minimal)  VARIANT="minimal";          shift   ;;
            --server)   VARIANT="server";           shift   ;;
            --help|-h)  show_help; exit 0           ;;
            *)
                log_error "Unknown argument: $1"
                echo ""; show_help; exit 1 ;;
        esac
    done

    case "$VARIANT" in
        standard|minimal|server) ;;
        *)
            log_error "Invalid variant: '$VARIANT'. Use: standard | minimal | server"
            exit 1 ;;
    esac

    ISO_NAME="sentinelx-${SX_VERSION}-${VARIANT}-${SX_ARCH}.iso"
    ROOTFS_DIR="${WORK_DIR}/rootfs"
    ISO_STAGING="${WORK_DIR}/iso"
    EFI_DIR="${WORK_DIR}/efi"
    SQUASHFS_IMG="${ISO_STAGING}/live/filesystem.squashfs"
    ISO_FILE="${OUTPUT_DIR}/${ISO_NAME}"
}

# ─────────────────────────────────────────────
#  STEP 1: PREFLIGHT CHECKS
# ─────────────────────────────────────────────
check_root() {
    [[ "$EUID" -eq 0 ]] || { log_error "Must run as root: sudo ./build-iso.sh"; exit 1; }
}

check_deps() {
    log_step "Step 1/9 — Preflight Checks"

    local REQUIRED=( "mksquashfs" "xorriso" "grub-mkrescue" "grub-mkimage"
                     "mcopy" "mformat" "sha256sum" "find" "du" )
    local MISSING=()
    for tool in "${REQUIRED[@]}"; do
        if command -v "$tool" &>/dev/null; then
            log_sub "Found: $tool"
        else
            MISSING+=("$tool")
            log_warn "Missing: $tool"
        fi
    done

    local OPTIONAL=( "pacstrap" "pacman" "dnf" "gpg" "isohybrid" )
    for tool in "${OPTIONAL[@]}"; do
        command -v "$tool" &>/dev/null && \
            log_dim "Optional found: $tool" || \
            log_dim "Optional missing: $tool"
    done

    if [ ${#MISSING[@]} -gt 0 ]; then
        log_error "Missing required tools: ${MISSING[*]}"
        echo "  Install on Arch:  pacman -S squashfs-tools xorriso grub mtools"
        echo "  Install on RHEL:  dnf install squashfs-tools xorriso grub2-tools mtools"
        exit 1
    fi

    # Disk space
    local WORK_PARENT; WORK_PARENT=$(dirname "$(realpath "$WORK_DIR" 2>/dev/null || echo "$WORK_DIR")")
    local FREE_GB=$(( $(df -k "$WORK_PARENT" 2>/dev/null | awk 'NR==2{print $4}' || echo 0) / 1024 / 1024 ))
    [[ "$FREE_GB" -lt 8 ]] && log_warn "Low disk: ${FREE_GB}GB free (recommend ≥8GB)" \
                            || log_sub  "Disk space: ${FREE_GB}GB free"

    # RAM
    local MEM_GB=$(( $(grep MemAvailable /proc/meminfo 2>/dev/null | awk '{print $2}' || echo 0) / 1024 / 1024 ))
    [[ "$MEM_GB" -lt 2 ]] && log_warn "Low memory: ${MEM_GB}GB (recommend ≥2GB)" \
                           || log_sub  "Memory: ${MEM_GB}GB available"

    log_info "Preflight checks passed."
    [[ "$CHECK_ONLY" -eq 1 ]] && { log_info "--check: Exiting without building."; exit 0; }
}

# ─────────────────────────────────────────────
#  STEP 2: PREPARE WORKSPACE
# ─────────────────────────────────────────────
prepare_workspace() {
    log_step "Step 2/9 — Preparing Workspace"

    [[ -d "$WORK_DIR" ]] && { log_sub "Removing old work dir"; rm -rf "$WORK_DIR"; }

    mkdir -p \
        "$ROOTFS_DIR" \
        "${ISO_STAGING}/boot/grub/themes/sentinelx" \
        "${ISO_STAGING}/live" \
        "${ISO_STAGING}/EFI/boot" \
        "$EFI_DIR" \
        "$OUTPUT_DIR" \
        "$LOG_DIR"

    log_info "Workspace ready."
}

# ─────────────────────────────────────────────
#  STEP 3: BUILD / IMPORT ROOTFS
# ─────────────────────────────────────────────
build_rootfs() {
    log_step "Step 3/9 — Building Root Filesystem (${VARIANT})"

    if [[ -n "$ROOTFS_PATH" ]]; then
        [[ -d "$ROOTFS_PATH" ]] || { log_error "Rootfs not found: $ROOTFS_PATH"; exit 1; }
        log_sub "Using provided rootfs: $ROOTFS_PATH"
        rsync -a --info=progress2 "${ROOTFS_PATH}/" "${ROOTFS_DIR}/"
        log_info "Rootfs imported."; return
    fi

    local -a PKG_LIST
    case "$VARIANT" in
        standard) PKG_LIST=("${PACKAGES_STANDARD[@]}") ;;
        minimal)  PKG_LIST=("${PACKAGES_MINIMAL[@]}")  ;;
        server)   PKG_LIST=("${PACKAGES_SERVER[@]}")   ;;
    esac

    log_sub "Packages to install: ${#PKG_LIST[@]}"

    if command -v pacstrap &>/dev/null; then
        log_sub "Bootstrap method: pacstrap (Arch)"
        pacstrap -K "$ROOTFS_DIR" "${PKG_LIST[@]}" 2>&1 | grep -v "^warning: " || true
    elif command -v dnf &>/dev/null; then
        log_sub "Bootstrap method: dnf --installroot (Red Hat)"
        mkdir -p "${ROOTFS_DIR}/var/lib/rpm"
        rpm --root "$ROOTFS_DIR" --initdb
        dnf install --installroot="$ROOTFS_DIR" --releasever=9 \
            --setopt=install_weak_deps=False -y "${PKG_LIST[@]}" 2>&1 | tail -20 || true
    else
        log_error "No bootstrap tool found (need pacstrap or dnf)."
        log_warn  "Provide a pre-built rootfs with: --rootfs <path>"
        exit 1
    fi

    log_info "Root filesystem built."
}

# ─────────────────────────────────────────────
#  STEP 4: CONFIGURE ROOTFS
# ─────────────────────────────────────────────
_chroot_run() { chroot "$ROOTFS_DIR" /bin/bash -c "$1" 2>/dev/null || true; }

configure_rootfs() {
    log_step "Step 4/9 — Configuring Root Filesystem"

    echo "sentinelx" > "${ROOTFS_DIR}/etc/hostname"

    cat > "${ROOTFS_DIR}/etc/hosts" << 'EOF'
127.0.0.1   localhost
127.0.1.1   sentinelx
::1         localhost ip6-localhost ip6-loopback
EOF

    cat > "${ROOTFS_DIR}/etc/locale.conf" << 'EOF'
LANG=en_US.UTF-8
LC_TIME=en_US.UTF-8
EOF
    echo "en_US.UTF-8 UTF-8" >> "${ROOTFS_DIR}/etc/locale.gen" 2>/dev/null || true
    ln -sf /usr/share/zoneinfo/UTC "${ROOTFS_DIR}/etc/localtime"
    log_sub "Hostname / locale / timezone set"

    # Live user
    local LIVE_USER="sentinel" LIVE_PASS="sentinel"
    _chroot_run "useradd -m -G wheel,audio,video,network -s /bin/bash $LIVE_USER"
    _chroot_run "echo '${LIVE_USER}:${LIVE_PASS}' | chpasswd"
    _chroot_run "echo 'root:${LIVE_PASS}' | chpasswd"
    echo "${LIVE_USER} ALL=(ALL) NOPASSWD:ALL" > "${ROOTFS_DIR}/etc/sudoers.d/sentinelx-live"
    chmod 440 "${ROOTFS_DIR}/etc/sudoers.d/sentinelx-live"
    log_sub "Live user: $LIVE_USER / $LIVE_PASS"

    # Autologin tty1
    local GETTY_DIR="${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d"
    mkdir -p "$GETTY_DIR"
    printf '[Service]\nExecStart=\nExecStart=-/sbin/agetty --autologin %s --noclear %%I $TERM\n' \
        "$LIVE_USER" > "${GETTY_DIR}/autologin.conf"
    log_sub "Autologin configured"

    # Enable services
    local SERVICES=("NetworkManager" "systemd-resolved" "systemd-timesyncd" "apparmor" "auditd")
    [[ "$VARIANT" == "server" ]] && SERVICES+=("sshd" "firewalld")
    for svc in "${SERVICES[@]}"; do
        _chroot_run "systemctl enable ${svc}" && log_sub "Enabled: $svc" || true
    done

    # fstab
    echo "tmpfs   /tmp    tmpfs   defaults,nosuid,nodev    0 0" > "${ROOTFS_DIR}/etc/fstab"

    # Install sx-pkg & sx-harden
    local SCRIPT_DIR; SCRIPT_DIR="$(dirname "$(realpath "$0")")"
    local SX_PKG_SRC="${SCRIPT_DIR}/../packages/sx-pkg"
    local SX_HARDEN_SRC="${SCRIPT_DIR}/../security/hardening/sx-harden"
    [[ -f "$SX_PKG_SRC"    ]] && install -m 755 "$SX_PKG_SRC"    "${ROOTFS_DIR}/usr/local/bin/sx-pkg"    && log_sub "sx-pkg installed"
    [[ -f "$SX_HARDEN_SRC" ]] && install -m 755 "$SX_HARDEN_SRC" "${ROOTFS_DIR}/usr/local/bin/sx-harden" && log_sub "sx-harden installed"

    # AppArmor profiles
    local AA_SRC="${SCRIPT_DIR}/../security/apparmor"
    if [[ -d "$AA_SRC" ]]; then
        mkdir -p "${ROOTFS_DIR}/etc/apparmor.d/abstractions"
        cp -r "${AA_SRC}/"* "${ROOTFS_DIR}/etc/apparmor.d/" 2>/dev/null || true
        log_sub "AppArmor profiles installed"
    fi

    # MOTD
    cat > "${ROOTFS_DIR}/etc/motd" << 'EOF'

  ███████╗███████╗███╗   ██╗████████╗██╗███╗   ██╗███████╗██╗
  ██╔════╝██╔════╝████╗  ██║╚══██╔══╝██║████╗  ██║██╔════╝██║
  ███████╗█████╗  ██╔██╗ ██║   ██║   ██║██╔██╗ ██║█████╗  ██║
  ╚════██║██╔══╝  ██║╚██╗██║   ██║   ██║██║╚██╗██║██╔══╝  ██║
  ███████║███████╗██║ ╚████║   ██║   ██║██║ ╚████║███████╗███████╗
  ╚══════╝╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝

  SentinelX OS Live Environment
  Login: sentinel / sentinel  |  sudo: no password required
  Install: sudo sx-install

EOF

    # os-release
    cat > "${ROOTFS_DIR}/etc/os-release" << EOF
NAME="SentinelX OS"
PRETTY_NAME="SentinelX OS ${SX_VERSION} (${SX_CODENAME})"
ID=sentinelx
ID_LIKE="arch rhel fedora"
VERSION="${SX_VERSION}"
VERSION_CODENAME="${SX_CODENAME}"
BUILD_ID="${BUILD_DATE}"
HOME_URL="${SX_URL}"
ANSI_COLOR="1;36"
EOF

    log_info "Rootfs configuration complete."
}

# ─────────────────────────────────────────────
#  STEP 5: INSTALL KERNEL
# ─────────────────────────────────────────────
install_kernel() {
    log_step "Step 5/9 — Installing Kernel"

    local VMLINUZ=""
    if   [[ -n "$KERNEL_PATH" && -f "$KERNEL_PATH" ]]; then
        VMLINUZ="$KERNEL_PATH"
    elif ls "${ROOTFS_DIR}/boot/vmlinuz-"*"-sx" &>/dev/null 2>&1; then
        VMLINUZ=$(ls "${ROOTFS_DIR}/boot/vmlinuz-"*"-sx" | head -1)
    elif ls "${ROOTFS_DIR}/boot/vmlinuz-"* &>/dev/null 2>&1; then
        VMLINUZ=$(ls "${ROOTFS_DIR}/boot/vmlinuz-"* | head -1)
    elif ls /boot/vmlinuz-* &>/dev/null 2>&1; then
        VMLINUZ=$(ls /boot/vmlinuz-* | head -1)
        log_warn "Using host kernel as fallback: $VMLINUZ"
    else
        log_error "No kernel found. Run kernel/build.sh first."
        exit 1
    fi

    cp "$VMLINUZ" "${ISO_STAGING}/boot/vmlinuz"
    log_sub "Kernel → ${ISO_STAGING}/boot/vmlinuz"

    # Generate or copy initramfs
    local KVER; KVER=$(basename "$VMLINUZ" | sed 's/vmlinuz-//')
    local INITRAMFS="${ISO_STAGING}/boot/initrd.img"

    if _chroot_run "command -v mkinitcpio"; then
        _chroot_run "mkinitcpio -k '${KVER}' -g /boot/initramfs-live.img -S autodetect" || \
        _chroot_run "mkinitcpio -p linux" || true
    elif _chroot_run "command -v dracut"; then
        _chroot_run "dracut --force --add 'dmsquash-live' /boot/initramfs-live.img '${KVER}'" || true
    fi

    local CHROOT_INITRD; CHROOT_INITRD=$(ls "${ROOTFS_DIR}/boot/initramfs-"*".img" 2>/dev/null | head -1 || echo "")
    if [[ -n "$CHROOT_INITRD" ]]; then
        cp "$CHROOT_INITRD" "$INITRAMFS"
    else
        local HOST_INITRD; HOST_INITRD=$(ls /boot/initramfs-*.img /boot/initrd.img-* 2>/dev/null | head -1 || echo "")
        [[ -n "$HOST_INITRD" ]] && { cp "$HOST_INITRD" "$INITRAMFS"; log_warn "Using host initramfs as fallback"; } \
                                 || { log_error "No initramfs available."; exit 1; }
    fi

    log_sub "Initramfs → $INITRAMFS"
    log_info "Kernel installed."
}

# ─────────────────────────────────────────────
#  STEP 6: BUILD SQUASHFS
# ─────────────────────────────────────────────
build_squashfs() {
    log_step "Step 6/9 — Building SquashFS (xz compression)"

    mkdir -p "$(dirname "$SQUASHFS_IMG")"
    log_sub "Source: $ROOTFS_DIR"
    log_sub "Target: $SQUASHFS_IMG"
    log_sub "Compressing — this may take several minutes..."

    mksquashfs "$ROOTFS_DIR" "$SQUASHFS_IMG" \
        -comp xz -Xbcj x86 -b 1M -no-progress -noappend \
        -e boot -e proc -e sys -e dev -e run -e tmp \
        -e "var/cache/pacman/pkg" -e "var/cache/dnf" \
        -e "var/log" -e "root/.bash_history" \
        2>&1 | tail -3

    local SQUASH_SIZE; SQUASH_SIZE=$(du -sh "$SQUASHFS_IMG" | cut -f1)
    log_sub "SquashFS size: $SQUASH_SIZE"

    # filesystem.size for live-boot
    du -s --block-size=1 "$ROOTFS_DIR" | cut -f1 > "${ISO_STAGING}/live/filesystem.size"

    log_info "SquashFS built."
}

# ─────────────────────────────────────────────
#  STEP 7: CONFIGURE BOOTLOADER
# ─────────────────────────────────────────────
configure_bootloader() {
    log_step "Step 7/9 — Configuring GRUB Bootloader"

    cat > "${ISO_STAGING}/boot/grub/grub.cfg" << EOF
# SentinelX OS GRUB Configuration
# Generated by build-iso.sh v${SX_VERSION}

set default="0"
set timeout=10
set timeout_style=menu

if [ -f "/boot/grub/themes/sentinelx/theme.txt" ]; then
    set theme="/boot/grub/themes/sentinelx/theme.txt"
    export theme
fi

set SX_PARAMS="quiet splash loglevel=3 apparmor=1 security=apparmor"
set SX_LIVE="boot=live components toram"

menuentry "SentinelX OS ${SX_VERSION} — Live (${VARIANT})" --class sentinelx {
    linux  /boot/vmlinuz \${SX_LIVE} \${SX_PARAMS}
    initrd /boot/initrd.img
}

menuentry "SentinelX OS — Live (Safe Mode)" --class sentinelx {
    linux  /boot/vmlinuz \${SX_LIVE} nomodeset xdriver=vesa noacpi nosplash
    initrd /boot/initrd.img
}

menuentry "SentinelX OS — Install to Disk" --class sentinelx {
    linux  /boot/vmlinuz \${SX_LIVE} \${SX_PARAMS} sx_install=1
    initrd /boot/initrd.img
}

if [ "\${grub_platform}" = "efi" ]; then
    menuentry "UEFI Firmware Settings" { fwsetup }
fi

menuentry "Boot from first disk" { set root=(hd0); chainloader +1 }
menuentry "Reboot"   { reboot }
menuentry "Shutdown" { halt }
EOF
    log_sub "grub.cfg written"

    # GRUB theme
    cat > "${ISO_STAGING}/boot/grub/themes/sentinelx/theme.txt" << 'EOF'
title-text: "SentinelX OS"
title-color: "#00e5ff"
title-font: "Sans Bold 20"
desktop-color: "#0a0e1a"
+ boot_menu {
  left: 20%
  top: 30%
  width: 60%
  height: 40%
  item_font: "Sans 14"
  item_color: "#aaaaaa"
  selected_item_color: "#ffffff"
  item_height: 36
  item_padding: 10
}
+ label {
  left: 20%
  top: 78%
  width: 60%
  align: "center"
  font: "Sans 11"
  color: "#555e7a"
  text: "↑↓ Navigate · Enter Select · 'e' Edit"
}
+ progress_bar {
  id: "__timeout__"
  left: 20%
  top: 88%
  width: 60%
  height: 8
  fg_color: "#00e5ff"
  bg_color: "#1a1f33"
}
EOF
    log_sub "GRUB theme written"

    # EFI image
    log_sub "Building GRUB EFI image..."
    grub-mkimage \
        --format=x86_64-efi \
        --output="${ISO_STAGING}/EFI/boot/bootx64.efi" \
        --prefix="/boot/grub" \
        part_gpt part_msdos fat ext2 btrfs iso9660 normal \
        linux echo ls cat chain boot search search_fs_uuid \
        configfile gfxterm gfxmenu all_video video_fb png jpeg font \
        minicmd test true \
        2>/dev/null || log_warn "grub-mkimage EFI failed — UEFI boot may not work"
    log_sub "EFI image built"

    # BIOS image
    log_sub "Building GRUB BIOS image..."
    mkdir -p "${ISO_STAGING}/boot/grub/i386-pc"
    grub-mkimage \
        --format=i386-pc \
        --output="${ISO_STAGING}/boot/grub/i386-pc/core.img" \
        --prefix="/boot/grub" \
        biosdisk part_gpt part_msdos iso9660 \
        normal linux echo ls cat chain boot search configfile gfxterm all_video \
        2>/dev/null || log_warn "grub-mkimage BIOS failed — legacy boot may not work"
    log_sub "BIOS image built"

    # Copy GRUB modules
    for d in /usr/lib/grub/x86_64-efi /usr/share/grub/x86_64-efi; do
        if [[ -d "$d" ]]; then
            mkdir -p "${ISO_STAGING}/boot/grub/x86_64-efi"
            cp "${d}/"*.mod "${ISO_STAGING}/boot/grub/x86_64-efi/" 2>/dev/null || true
            log_sub "GRUB EFI modules copied from $d"; break
        fi
    done

    log_info "Bootloader configured."
}

# ─────────────────────────────────────────────
#  STEP 8: ASSEMBLE ISO
# ─────────────────────────────────────────────
assemble_iso() {
    log_step "Step 8/9 — Assembling ISO Image"

    cat > "${ISO_STAGING}/.sentinelx-release" << EOF
SentinelX OS ${SX_VERSION} (${SX_CODENAME})
Variant: ${VARIANT} | Arch: ${SX_ARCH} | Built: ${BUILD_TS}
EOF

    pushd "$ISO_STAGING" > /dev/null
    find . -type f ! -name "md5sum.txt" -exec md5sum {} \; > md5sum.txt
    popd > /dev/null
    log_sub "md5sum.txt written"

    log_sub "Running xorriso..."
    mkdir -p "$OUTPUT_DIR"

    local ISOHDPFX=""
    for f in /usr/lib/grub/i386-pc/isohdpfx.bin \
              /usr/lib/grub2/i386-pc/isohdpfx.bin \
              /usr/share/grub/isohdpfx.bin; do
        [[ -f "$f" ]] && { ISOHDPFX="$f"; break; }
    done

    local XORRISO_ARGS=(
        -as mkisofs
        -iso-level 3
        -full-iso9660-filenames
        -volid "$SX_LABEL"
        -appid "$SX_PUBLISHER"
        -publisher "$SX_PUBLISHER"
        -preparer "build-iso.sh v${SX_VERSION}"
        -eltorito-boot boot/grub/i386-pc/core.img
        -eltorito-catalog boot/grub/boot.cat
        -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info
        -eltorito-alt-boot
        -e EFI/boot/bootx64.efi
        -no-emul-boot
        -isohybrid-gpt-basdat
        -output "$ISO_FILE"
    )
    [[ -n "$ISOHDPFX" ]] && XORRISO_ARGS+=(-isohybrid-mbr "$ISOHDPFX")
    XORRISO_ARGS+=("$ISO_STAGING")

    xorriso "${XORRISO_ARGS[@]}" 2>&1 | grep -v "^xorriso : UPDATE" | tail -10 || {
        log_warn "xorriso failed, retrying without isohybrid-mbr..."
        xorriso -as mkisofs -iso-level 3 -full-iso9660-filenames \
            -volid "$SX_LABEL" -appid "$SX_PUBLISHER" \
            -eltorito-boot boot/grub/i386-pc/core.img \
            -eltorito-catalog boot/grub/boot.cat \
            -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
            -eltorito-alt-boot -e EFI/boot/bootx64.efi -no-emul-boot \
            -output "$ISO_FILE" "$ISO_STAGING" 2>&1 | tail -5
    }

    log_sub "ISO size: $(du -sh "$ISO_FILE" | cut -f1)"
    log_info "ISO assembled: $ISO_FILE"
}

# ─────────────────────────────────────────────
#  STEP 9: CHECKSUM & SIGN
# ─────────────────────────────────────────────
finalize() {
    log_step "Step 9/9 — Checksums & Finalization"

    pushd "$OUTPUT_DIR" > /dev/null

    sha256sum "$ISO_NAME" > "${ISO_NAME}.sha256" && log_sub "SHA256 written"
    sha512sum "$ISO_NAME" > "${ISO_NAME}.sha512" && log_sub "SHA512 written"
    md5sum    "$ISO_NAME" > "${ISO_NAME}.md5"    && log_sub "MD5 written"
    cat "${ISO_NAME}.sha256"

    if [[ "$SIGN" -eq 1 ]]; then
        local GPG_ARGS=("--armor" "--detach-sign")
        [[ -n "$GPG_KEY" ]] && GPG_ARGS+=("--default-key" "$GPG_KEY")
        gpg "${GPG_ARGS[@]}" "$ISO_NAME" && log_info "GPG signature → ${ISO_NAME}.asc" \
                                         || log_warn "GPG signing failed"
    fi

    cat > "${ISO_NAME}.manifest" << EOF
SentinelX OS ISO Build Manifest
═══════════════════════════════════════════
File:     ${ISO_NAME}
Version:  ${SX_VERSION} (${SX_CODENAME})
Variant:  ${VARIANT}
Arch:     ${SX_ARCH}
Built:    ${BUILD_TS}
Size:     $(du -h "$ISO_NAME" | cut -f1)
SHA256:   $(cut -d' ' -f1 "${ISO_NAME}.sha256")
EOF
    log_sub "Manifest written"
    popd > /dev/null

    [[ "$CLEAN" -eq 1 ]] && { rm -rf "$WORK_DIR"; log_sub "Work dir cleaned."; } \
                          || log_sub "Work dir kept: $WORK_DIR (--no-clean)"

    log_info "Finalization complete."
}

# ─────────────────────────────────────────────
#  FINAL REPORT
# ─────────────────────────────────────────────
print_success() {
    local ISO_SIZE; ISO_SIZE=$(du -sh "${ISO_FILE}" 2>/dev/null | cut -f1 || echo "unknown")
    echo ""
    echo -e "${GREEN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║           SentinelX OS ISO Build Complete!           ║"
    echo "╠══════════════════════════════════════════════════════╣"
    printf "║  ISO     : %-44s║\n" "$ISO_FILE"
    printf "║  Size    : %-44s║\n" "$ISO_SIZE"
    printf "║  Variant : %-44s║\n" "$VARIANT"
    printf "║  Log     : %-44s║\n" "$LOG_FILE"
    echo "╠══════════════════════════════════════════════════════╣"
    echo "║  Test with QEMU:                                     ║"
    echo "║    qemu-system-x86_64 -cdrom <iso> -m 2G -enable-kvm║"
    echo "║  Write to USB:                                       ║"
    echo "║    dd if=<iso> of=/dev/sdX bs=4M status=progress     ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ─────────────────────────────────────────────
#  MAIN
# ─────────────────────────────────────────────
main() {
    parse_args "$@"
    _setup_log
    print_banner
    check_root
    check_deps
    prepare_workspace
    build_rootfs
    configure_rootfs
    install_kernel
    build_squashfs
    configure_bootloader
    assemble_iso
    finalize
    print_success
}

main "$@"
