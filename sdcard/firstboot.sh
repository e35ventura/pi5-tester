#!/bin/bash

# This script runs on the first boot to configure the tester SD card.
# It is placed in /boot/ and will be executed automatically.
# Runs as root on FIRST boot only, because we place it in /boot and delete it.

LOG_FILE="/boot/firstboot.log"
echo "[$(date)] Starting first boot setup..." >> $LOG_FILE

# 1. Install dependencies
apt-get update >> $LOG_FILE 2>&1
apt-get install -y i2c-tools alsa-utils >> $LOG_FILE 2>&1
echo "[$(date)] Dependencies installed." >> $LOG_FILE

# 2. Enable I2C bus 1 (pins 0/1 on Pi-5)
raspi-config nonint do_i2c 0 >> $LOG_FILE 2>&1
echo "[$(date)] I2C enabled." >> $LOG_FILE

# 3. Create tester directory and copy validator script
TESTER_DIR="/home/pi/tester"
VALIDATOR_SCRIPT="pi_validator.py"
mkdir -p $TESTER_DIR
cp /boot/$VALIDATOR_SCRIPT $TESTER_DIR/$VALIDATOR_SCRIPT
chown pi:pi $TESTER_DIR/$VALIDATOR_SCRIPT
chmod +x $TESTER_DIR/$VALIDATOR_SCRIPT
echo "[$(date)] Validator script copied to $TESTER_DIR." >> $LOG_FILE

# 4. Create /etc/rc.local to run the validator on boot
RC_LOCAL_FILE="/etc/rc.local"
cat << EOF > $RC_LOCAL_FILE
#!/bin/bash
setterm --blank 0 --powersave off --powerdown 0
$TESTER_DIR/$VALIDATOR_SCRIPT | tee /boot/pi_last.json
exit 0
EOF

chmod +x $RC_LOCAL_FILE
systemctl enable rc-local
echo "[$(date)] $RC_LOCAL_FILE created." >> $LOG_FILE

# 5. Clean up first-boot files
rm /boot/$VALIDATOR_SCRIPT
rm /boot/firstboot.sh
echo "[$(date)] First boot setup complete. Cleanup finished." >> $LOG_FILE

# Reboot to apply all changes and start fresh
reboot
