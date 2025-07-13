# Raspberry Pi 5 "Tester" — Repository Architecture

This repository makes it **trivial to validate Raspberry Pi 5 boards** in three scenarios:

1. **SD-card boot** — the classic method (works standalone with HDMI or USB-serial)
2. **USB-device (gadget) boot** — SD-card present but JSON streams over the same USB-C cable
3. **Zero-media USB boot (rpiboot)** — *no* SD-card: the host PC pushes a kernel + tiny init-ramdisk; the Pi runs the validator and powers off

All three reuse the single `pi_validator.py` hardware-check script.

---

## Directory layout

```
pi5-tester/
├── docs/                    # Additional guides, troubleshooting, FAQ
│   └── ARCHITECTURE.md      # (this same content, copied for GH Pages)
├── pi_validator.py          # ✅ Common validator imported by every method
├── sdcard/                  # Files for the SD-card approach
│   ├── firstboot.sh         # One-shot provisioning script (runs on first boot)
│   ├── make_card.sh         # macOS helper — flashes & stages files in one go
│   └── config_snippets/     # lines to append to config.txt & cmdline.txt for gadget mode
├── usbboot/                 # Zero-media USB-boot assets
│   ├── initramfs/           # Minimal ram-disk (kernel modules + BusyBox + validator)
│   │   ├── init             # /init script that runs pi_validator.py then poweroff
│   │   └── modules/         # *.ko files copied from a Pi-5 kernel build
│   ├── build_initramfs.sh   # Reproducible build script (Debian initramfs-tools)
│   └── rpiboot.conf         # Convenience wrapper for the usbboot utility
└── README.md                # ← you are here
```

> **Tip:** keep *all* hardware-agnostic logic inside `pi_validator.py`.  Each boot
> target only needs to worry about how Linux starts and how the JSON is carried
> back to the operator.

---

## 1 · SD-card method (baseline)

1. Flash Raspberry Pi OS Lite (64-bit) to a micro-SD.
2. Copy `pi_validator.py` to the FAT32 `boot` partition.
3. Copy `sdcard/firstboot.sh` to the same place.
4. Boot one Pi once → `firstboot.sh` installs packages, enables I²C, writes
   `/etc/rc.local`, removes itself.
5. Subsequent boots on **any** Pi automatically run the validator and save the
   JSON to `/boot/pi_last.json`.

**USB-serial add-on:** append the two lines in
`sdcard/config_snippets/gadget.txt` to `config.txt` and `cmdline.txt` to mirror
output to `/dev/ttyGS0`.

---

## 2 · USB-gadget over existing SD-card

Same SD-card as above, but with `g_serial` (or `g_ether`) loaded early so the
host PC sees a virtual serial or Ethernet device over the USB-C port.  Your
operator just opens a 115200-baud terminal and reads the JSON.

All changes for this mode live in `sdcard/config_snippets/`.

---

## 3 · Zero-media USB-boot (rpiboot)

The `usbboot/` folder contains everything to boot a *blank* Pi-5 board:

1. `build_initramfs.sh` — reproducibly assembles a few-megabyte cpio archive
   containing:
   * BusyBox + essential libs
   * kernel modules: `i2c_bcm2835`, `i2c_dev`, `at24`, `dwc2`, **optional** audio drivers
   * `/init` script that mounts `proc`/`sys`, modprobes, runs `pi_validator.py`,
     tees JSON to `/dev/ttyGS0`, then `poweroff -f`
2. `rpiboot.conf` points the `usbboot` helper at the correct kernel (`kernel8.img`)
   and the freshly built `initramfs.cpio`.

**Operator flow**
```
host$ cd usbboot && sudo rpiboot -d .
[plug Pi-5]
... device enumerates, pulls files ...
JSON arrives over USB-serial → logged to host file system
Pi powers off automatically → operator unplugs, next board in
```

Cycle time < 20 s; nothing written to the Pi.

---

## Local development

```
# optional virtualenv
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt   # none today, but kept for future libs
python pi_validator.py            # runs on any Linux host for unit tests
```

Use `flake8` + `black` before opening a PR.

---

## Contributing & future ideas

* S3 / e-mail upload helpers
* Expand audio loop-back to run on non-WM8960 codecs
* GitHub Actions that build and attach the latest `initramfs.cpio` artifact
* Dashboard that watches a directory of JSONs and highlights failures

PRs are welcome!
