#!/usr/bin/env bash

#===============================================================================
#   CachyOS / Arch VM Creator & Backup Manager (QEMU/KVM)
#===============================================================================

VM_DIR="$HOME/CachyOS_Test_VM"
ISO_NAME="cachyos-desktop.iso"
ISO_PATH="$VM_DIR/$ISO_NAME"
DISK_PATH="$VM_DIR/cachyos_test.qcow2"
BACKUP_DISK="$VM_DIR/cachyos_test_clean_backup.qcow2"
DISK_SIZE="25G"
RAM_SIZE="4096" # 4GB RAM
CPU_CORES="4"

BOOT_MODE="menu" # menu, iso, hd, backup, restore

for arg in "$@"; do
    case $arg in
        --installed|--hd|-hd)
            BOOT_MODE="hd"
            ;;
        --iso|-iso)
            BOOT_MODE="iso"
            ;;
        --backup)
            BOOT_MODE="backup"
            ;;
        --restore)
            BOOT_MODE="restore"
            ;;
    esac
done

mkdir -p "$VM_DIR"

# Quick Backup Mode
if [ "$BOOT_MODE" = "backup" ]; then
    echo "💾 Creating clean snapshot backup of virtual disk..."
    if [ -f "$DISK_PATH" ]; then
        cp "$DISK_PATH" "$BACKUP_DISK"
        echo "✓ Backup created successfully at: $BACKUP_DISK"
    else
        echo "❌ Virtual disk $DISK_PATH not found!"
    fi
    exit 0
fi

# Quick Restore Mode
if [ "$BOOT_MODE" = "restore" ]; then
    echo "🔄 Restoring virtual disk from clean snapshot backup..."
    if [ -f "$BACKUP_DISK" ]; then
        cp "$BACKUP_DISK" "$DISK_PATH"
        echo "✓ Restored $DISK_PATH to clean backup state!"
    else
        echo "❌ Backup file $BACKUP_DISK not found!"
    fi
    exit 0
fi

echo "================================================================="
echo "   🖥️ CachyOS Virtual Machine Installer & Tester (QEMU/KVM)"
echo "================================================================="

# 1. Verify QEMU installation
if ! command -v qemu-system-x86_64 &>/dev/null || ! command -v qemu-img &>/dev/null; then
    echo "⚠️ QEMU is not installed. Updating pacman DB and installing qemu-desktop..."
    sudo pacman -Sy --needed --noconfirm qemu-desktop qemu-system-x86 edk2-ovmf
fi

# 2. Boot Mode Selection
if [ "$BOOT_MODE" = "menu" ]; then
    echo "اختر وضع التشغيل / Select Mode:"
    echo "  [1] Boot Installed System / الإقلاع من النظام المثبت على الهارد الوهمي"
    echo "  [2] Boot Live ISO Installer / الإقلاع من أسطوانة التثبيت Live ISO"
    echo "  [3] Create Clean Backup / أخذ نسخة احتياطية من الهارد الوهمي الآن"
    echo "  [4] Restore Clean Backup / استعادة النسخة الاحتياطية النظيفة للهارد"
    read -p "اختر الخيار [1/2/3/4] (Default: 1): " choice
    case $choice in
        2) BOOT_MODE="iso" ;;
        3)
            echo "💾 Creating backup copy of $DISK_PATH..."
            [ -f "$DISK_PATH" ] && cp "$DISK_PATH" "$BACKUP_DISK" && echo "✓ Backup created: $BACKUP_DISK"
            exit 0
            ;;
        4)
            echo "🔄 Restoring backup..."
            [ -f "$BACKUP_DISK" ] && cp "$BACKUP_DISK" "$DISK_PATH" && echo "✓ Restored $DISK_PATH"
            exit 0
            ;;
        *) BOOT_MODE="hd" ;;
    esac
fi

# 3. Handle ISO download if ISO boot is needed
if [ "$BOOT_MODE" = "iso" ]; then
    if [ -f "$ISO_PATH" ]; then
        ISO_SIZE=$(stat -c%s "$ISO_PATH" 2>/dev/null || echo 0)
        if [ "$ISO_SIZE" -lt 1000000000 ]; then
            echo "⚠️ Removing invalid ISO file ($ISO_SIZE bytes)..."
            rm -f "$ISO_PATH"
        fi
    fi

    if [ ! -f "$ISO_PATH" ]; then
        echo "📥 Downloading CachyOS Live ISO (3.1 GB)..."
        PRIMARY_URL="https://mirror.cachyos.org/ISO/desktop/260628/cachyos-desktop-linux-260628.iso"
        FALLBACK_URL="https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso"
        
        if ! curl -C - -fL --progress-bar -o "$ISO_PATH" "$PRIMARY_URL"; then
            echo "Fallback: Downloading Arch Linux Live ISO..."
            curl -C - -fL --progress-bar -o "$ISO_PATH" "$FALLBACK_URL"
        fi
    fi
fi

# 4. Create QCOW2 Virtual Disk if not present
if [ ! -f "$DISK_PATH" ]; then
    echo "💾 Creating $DISK_SIZE Virtual Disk image..."
    qemu-img create -f qcow2 "$DISK_PATH" "$DISK_SIZE"
    echo "✓ Virtual disk created."
fi

# 5. Check KVM Acceleration
KVM_FLAG=""
if [ -e /dev/kvm ] && [ -w /dev/kvm ]; then
    KVM_FLAG="-enable-kvm -cpu host"
    echo "⚡ KVM Hardware Acceleration: ENABLED"
else
    KVM_FLAG="-cpu max"
    echo "⚠️ KVM not accessible. Running in software emulation mode."
fi

echo -e "\n================================================================="
if [ "$BOOT_MODE" = "hd" ]; then
    echo "   🚀 Booting Installed CachyOS System from Hard Disk..."
else
    echo "   🚀 Booting CachyOS Live ISO Installer..."
fi
echo "================================================================="

# 6. Launch QEMU VM based on chosen boot mode
if [ "$BOOT_MODE" = "hd" ]; then
    qemu-system-x86_64 \
        $KVM_FLAG \
        -smp "$CPU_CORES" \
        -m "$RAM_SIZE" \
        -vga virtio \
        -display default,show-cursor=on \
        -drive file="$DISK_PATH",format=qcow2,if=virtio \
        -boot order=c \
        -net nic,model=virtio -net user
else
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
fi
