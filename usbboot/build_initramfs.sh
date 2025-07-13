#!/usr/bin/env bash
# Build a minimal initramfs for zero-media USB-boot (rpiboot)
set -euo pipefail

IMG=initramfs.cpio
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/bin" "$WORK/sbin" "$WORK/proc" "$WORK/sys" "$WORK/dev" "$WORK/modules"

# 1. BusyBox static
cp $(which busybox) "$WORK/bin/"
ln -s busybox "$WORK/bin/sh"
for app in mount modprobe poweroff sha256sum strings awk head tee; do
  ln -s busybox "$WORK/bin/$app"
done

# 2. Copy pi_validator.py
cp ../pi_validator.py "$WORK/"

# 3. /init script
cat >"$WORK/init" <<'EOF'
#!/bin/sh
set -eux
mount -t proc none /proc
mount -t sysfs none /sys

# modules path points to /modules
export MODDIR=/modules
modprobe -q i2c_bcm2835 || true
modprobe -q i2c_dev || true
modprobe -q at24 || true
modprobe -q dwc2 || true
modprobe -q g_serial || true

# run validator
/ pi_validator.py | tee /dev/ttyGS0 > /stdout.json
poweroff -f
EOF
chmod +x "$WORK/init"

# 4. Add kernel modules supplied manually into usbboot/modules before run
if [ -d modules ]; then
  cp -r modules/* "$WORK/modules/"
fi

# 5. Create cpio archive
(cd "$WORK" && find . | cpio -o -H newc | gzip) > "$IMG"

echo "Created $IMG ($(du -h "$IMG" | cut -f1))"
