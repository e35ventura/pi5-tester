#!/usr/bin/env bash
# Fetch Raspberry Pi kernel + modules and build ready-to-use usbboot assets.
#
# Prerequisites: curl, ar, tar, gzip, cpio, busybox, and build_initramfs.sh in
# the same directory.  Works on Linux or macOS with Homebrew coreutils.
set -euo pipefail

mirror=https://archive.raspberrypi.org/debian/pool/main/r/raspberrypi-firmware
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

cd "$(dirname "$0")"  # usbboot directory

# -----------------------------------------------------------------------------
# 1. Find latest arm64 kernel .deb
# -----------------------------------------------------------------------------

latest=$(curl -s $mirror/ | grep -oE 'raspberrypi-kernel_[^ ]+?_arm64.deb' | sort -V | tail -1)
if [[ -z "$latest" ]]; then
  echo "Could not determine latest kernel .deb" >&2; exit 1
fi

echo "Downloading $latest …"
curl -L "$mirror/$latest" -o "$work/kernel.deb"

# -----------------------------------------------------------------------------
# 2. Extract .deb (ar archive) → data.tar.xz → rootfs tree
# -----------------------------------------------------------------------------
cd "$work"
ar x kernel.deb data.tar.xz
mkdir rootfs && tar -C rootfs -xf data.tar.xz

modules_dir=$(find rootfs/lib/modules -mindepth 1 -maxdepth 1 -type d | head -1)
if [[ ! -d "$modules_dir" ]]; then
  echo "No modules directory found" >&2; exit 1
fi

kver=$(basename "$modules_dir")
echo "Kernel version: $kver"

# -----------------------------------------------------------------------------
# 3. Copy firmware blobs, kernel and DTBs to usbboot/
# -----------------------------------------------------------------------------
# Essential first-stage & GPU firmware the ROM requires
for f in bootcode4.bin start4.elf fixup4.dat; do
    if [[ -f rootfs/boot/$f ]]; then
        cp rootfs/boot/$f ../
    else
        echo "WARNING: $f missing from firmware package" >&2
    fi
done

# Kernel & DTBs
cp rootfs/boot/kernel8.img ../kernel8.img
cp -r rootfs/boot/*.dtb rootfs/boot/overlays ../ 2>/dev/null || true

echo "Firmware + kernel copied."

# -----------------------------------------------------------------------------
# 4. Build initramfs using extracted modules
# -----------------------------------------------------------------------------
cd - > /dev/null
./build_initramfs.sh "$modules_dir"

# -----------------------------------------------------------------------------
# 5. Minimal config.txt enabling I²C and gadget mode
# -----------------------------------------------------------------------------
cat >config.txt <<EOF
[all]
dtparam=i2c_arm=on
dtoverlay=dwc2,dr_mode=peripheral
EOF

echo "\nAll assets ready in usbboot/:"
echo "  kernel8.img"
echo "  initramfs.cpio.gz"
echo "  config.txt (edit as needed)"
echo "Run: sudo rpiboot -d usbboot"
