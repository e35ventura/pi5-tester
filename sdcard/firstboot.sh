#!/bin/bash
# One-shot provisioning script for the SD-card method.
# Runs as root on FIRST boot only, because we place it in /boot and delete it.
set -euxo pipefail

apt update
apt install -y i2c-tools

# Enable I2C bus 1 (pins 0/1 on Pi-5)
raspi-config nonint do_i2c 0

# Install validator for the pi user
install -d  -o pi -g pi /home/pi/tester
install -m 755 /boot/pi_validator.py /home/pi/tester/pi_validator.py

# Create rc.local
cat >/etc/rc.local <<'EOF'
#!/bin/bash
setterm --blank 0 --powersave off --powerdown 0
/home/pi/tester/pi_validator.py | tee /boot/pi_last.json
exit 0
EOF
chmod 755 /etc/rc.local
systemctl enable rc-local

# Remove self to avoid re-running on every boot
rm -f /boot/firstboot.sh
