#!/usr/bin/env bash

#===============================================================================
#   CachyOS VM Creator for Testing Dotfiles & System Setup
#   Launches a QEMU/KVM Virtual Machine with CachyOS ISO
#===============================================================================

VM_DIR="$HOME/CachyOS_Test_VM"
ISO_NAME="cachyos-desktop.iso"
ISO_PATH="$VM_DIR/$ISO_NAME"
DISK_PATH="$VM_DIR/cachyos_test.qcow2"
DISK_SIZE="25G"
RAM_SIZE="4096" # 4GB RAM
CPU_CORES="4"

echo "================================================================="
echo "   🖥️ CachyOS Virtual Machine Installer & Tester (QEMU/KVM)"
echo "================================================================="

# 1. Verify QEMU installation
if ! command -v qemu-system-x86_64 &>/dev/null || ! command -v qemu-img &>/dev/null; then
    echo "⚠️ QEMU is not installed. Updating pacman DB and installing qemu-desktop..."
    sudo pacman -Sy --needed --noconfirm qemu-desktop qemu-system-x86 edk2-ovmf
fi

mkdir -p "$VM_DIR"

# Check if existing ISO is invalid/corrupted (< 500MB)
if [ -f "$ISO_PATH" ]; then
    ISO_SIZE=$(stat -c%s "$ISO_PATH" 2>/dev/null || echo 0)
    if [ "$ISO_SIZE" -lt 500000000 ]; then
        echo "⚠️ Found broken/incomplete ISO file ($ISO_SIZE bytes). Deleting..."
        rm -f "$ISO_PATH"
    fi
fi

# 2. Check / Download CachyOS ISO
if [ ! -f "$ISO_PATH" ]; then
    echo "📥 Downloading CachyOS Live ISO (Please wait a moment)..."
    ISO_URL="https://sourceforge.net/projects/cachyos-arch/files/gui/cachyos-desktop-linux-latest.iso/download"
    
    if command -v curl &>/dev/null; then
        curl -C - -L -o "$ISO_PATH" "$ISO_URL" || {
            echo "Fallback: Downloading from official CachyOS mirror..."
            curl -C - -L -o "$ISO_PATH" "https://mirror.cachyos.org/ISO/desktop/260628/cachyos-desktop-linux-260628.iso"
        }
    elif command -v wget &>/dev/null; then
        wget -O "$ISO_PATH" "$ISO_URL"
    fi
else
    echo "✓ Found valid CachyOS ISO at: $ISO_PATH"
fi

# 3. Create QCOW2 Virtual Disk
if [ ! -f "$DISK_PATH" ]; then
    echo "💾 Creating $DISK_SIZE Virtual Disk image..."
    qemu-img create -f qcow2 "$DISK_PATH" "$DISK_SIZE"
    echo "✓ Virtual disk created."
else
    echo "✓ Virtual disk exists: $DISK_PATH"
fi

# 4. Check KVM Acceleration
KVM_FLAG=""
if [ -e /dev/kvm ] && [ -w /dev/kvm ]; then
    KVM_FLAG="-enable-kvm -cpu host"
    echo "⚡ KVM Hardware Acceleration: ENABLED"
else
    KVM_FLAG="-cpu max"
    echo "⚠️ KVM not accessible. Running in software emulation mode."
fi

echo -e "\n================================================================="
echo "   🚀 Booting CachyOS Test VM..."
echo "   Inside the VM, open terminal and run your one-liner to test:"
echo "   curl -sSL https://raw.githubusercontent.com/omarahmed321/new-config-cachyos/main/install.sh | bash"
echo "================================================================="

# 5. Launch QEMU VM
qemu-system-x86_64 \
    $KVM_FLAG \
    -smp "$CPU_CORES" \
    -m "$RAM_SIZE" \
    -vga virtio \
    -display default,show-cursor=on \
    -drive file="$DISK_PATH",format=qcow2,if=virtio \
    -cdrom "$ISO_PATH" \
    -boot order=d \
    -net nic,model=virtio -net user
