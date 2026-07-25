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
    echo "⚠️ QEMU is not installed. Installing qemu-desktop using pacman..."
    sudo pacman -S --needed --noconfirm qemu-desktop qemu-system-x86 edk2-ovmf
fi

mkdir -p "$VM_DIR"

# 2. Check / Download CachyOS ISO
if [ ! -f "$ISO_PATH" ]; then
    echo "📥 Downloading latest CachyOS Live ISO..."
    ISO_URL="https://mirror.cachyos.org/ISO/desktop/250119/cachyos-desktop-linux-250119.iso"
    
    if command -v curl &>/dev/null; then
        curl -L -o "$ISO_PATH" "$ISO_URL" || {
            echo "Fallback: Downloading from secondary CachyOS mirror..."
            curl -L -o "$ISO_PATH" "https://sourceforge.net/projects/cachyos-arch/files/gui/cachyos-desktop-linux-latest.iso/download"
        }
    elif command -v wget &>/dev/null; then
        wget -O "$ISO_PATH" "$ISO_URL"
    fi
else
    echo "✓ Found CachyOS ISO at: $ISO_PATH"
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
    echo "⚠️ KVM not accessible. Running in software emulation mode (slower)."
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
