# How to Create and Use the Pi 5 Tester SD Card

This guide provides simple, step-by-step instructions to create a special SD card that automatically tests Raspberry Pi 5 boards.

## You Will Need

*   A computer running Windows, macOS, or Linux.
*   A microSD card (8GB or larger is recommended).
*   A microSD card reader.
*   The `pi_validator.py` and `firstboot.sh` files from this project.

---

## Step 1: Flash the Raspberry Pi OS Image

1.  **Download the Raspberry Pi Imager:** Go to the [official Raspberry Pi website](https://www.raspberrypi.com/software/) and download and install the Imager application for your operating system.

2.  **Choose the OS:**
    *   Open the Raspberry Pi Imager.
    *   Click **CHOOSE OS**.
    *   Select **Raspberry Pi OS (other)**.
    *   Select **Raspberry Pi OS Lite (64-bit)**.

3.  **Choose Storage:**
    *   Insert your microSD card into the reader and connect it to your computer.
    *   Click **CHOOSE STORAGE** and select your microSD card.

4.  **Write the Image:**
    *   Click **WRITE**. The imager will download the OS and write it to your card. This may take several minutes.
    *   **Do not** use the "OS Customisation" feature at this stage.

---

## Step 2: Copy the Tester Scripts

1.  After the flash is complete, your computer may ask you to re-insert the SD card. Do so.
2.  Open the file explorer. You should see a new drive named `boot` or `bootfs`.
3.  Copy the following two files from this project directly into the `boot` drive:
    *   `pi_validator.py`
    *   `sdcard/firstboot.sh` (make sure to copy the file itself, not the directory)

4.  Once the files are copied, safely eject the SD card from your computer.

---

## Step 3: Run the Test

1.  Insert the prepared microSD card into a Raspberry Pi 5.
2.  Connect an HDMI monitor and power on the Pi.
3.  **First Boot Only:** The Pi will start up and automatically configure itself. This process involves installing software and setting up the test script. It will reboot automatically when finished. This will only happen the very first time you use the card.
4.  **Subsequent Boots:** On every boot after the first one, the Pi will:
    *   Run the `pi_validator.py` script.
    *   Display a block of JSON text on the screen for 15 seconds.
    *   Save the same JSON text to a file named `pi_last.json` on the `boot` partition of the SD card.

---

## Troubleshooting

### The Pi Doesn't Boot or Gets Stuck

If the Pi doesn't boot correctly after creating the card (especially if you see a black screen or a blinking cursor), the `/etc/rc.local` file might be causing a problem. Here’s how to fix it:

1.  **Mount the SD Card:** Insert the SD card back into your computer. You will only be able to see the `boot` partition.
2.  **Disable `rc.local`:** To fix the boot process, you need to edit a file on the main Linux partition, which isn't normally visible on Windows or macOS. The easiest way to do this is to modify the boot command line.
3.  **Edit `cmdline.txt`:**
    *   Open the `boot` drive.
    *   Find the file named `cmdline.txt` and open it in a plain text editor (like Notepad or TextEdit).
    *   At the very end of the single line of text, add a space and then `init=/bin/bash`.
    *   Save the file.
4.  **Repair in the Pi:**
    *   Eject the card, put it back in the Pi, and power it on.
    *   You will be dropped into a command prompt that looks something like `root@raspberrypi:/#`.
    *   Type the following commands, pressing Enter after each one:
        ```bash
        mount -o remount,rw /
        rm /etc/rc.local
        reboot
        ```
5.  **Clean Up:** After the Pi reboots successfully, shut it down, put the SD card back in your computer, and remove the `init=/bin/bash` text from `cmdline.txt`.

This will remove the problematic `rc.local` file, allowing the Pi to boot normally again. You can then re-examine the `firstboot.sh` script for errors and try the process again.
