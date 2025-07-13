#!/usr/bin/env python3
"""Hardware smoke-test for Raspberry Pi 5 boards.

On execution prints a JSON block with:
  timestamp   – UTC ISO-8601
  serial      – unique OTP serial number
  throttled   – bool (vcgencmd get_throttled != 0x0)
  hats[]      – zero-to-four HAT EEPROM summaries (addr, product, sha256)
  audio_ok    – optional, after 1-s WM8960 loopback test

The same JSON can be saved by the caller (e.g. rc.local) to /boot/pi_last.json
"""
import datetime, json, os, subprocess, sys, time
from pathlib import Path
from typing import List, Dict

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

def sh(cmd: str) -> str:
    """Return stdout of *cmd* (shell=True) trimmed."""
    return subprocess.check_output(cmd, shell=True, text=True).strip()

# -----------------------------------------------------------------------------
# Probes
# -----------------------------------------------------------------------------

def get_serial() -> str:
    return sh("awk '/^Serial/ {print $3}' /proc/cpuinfo")


def is_throttled() -> bool:
    val = sh("vcgencmd get_throttled").split("=")[-1]
    return val != "0x0"


def list_hats() -> List[Dict[str, str]]:
    hats = []
    for adr in ("50", "51", "52", "53"):
        eep = Path(f"/sys/bus/i2c/devices/1-00{adr}/eeprom")
        if eep.exists():
            hats.append(
                {
                    "addr": f"0x{adr}",
                    "product": sh(f"strings {eep} | head -1"),
                    "sha256": sh(f"sha256sum {eep}").split()[0],
                }
            )
    return hats


def check_audio() -> bool:
    """Optional 1-s playback/record smoke-test for WM8960-based HATs.

    Returns False if test fails or codec not present.  Implemented as a stub to
    avoid extra dependencies; feel free to enhance.
    """
    return False


def upload(result: dict) -> None:
    """Stub for e-mail/S3 upload.  Does nothing by default."""
    pass


# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

def main() -> None:
    result = {
        "timestamp": datetime.datetime.utcnow().isoformat(timespec="seconds") + "Z",
        "serial": get_serial(),
        "throttled": is_throttled(),
        "hats": list_hats(),
    }

    # Uncomment if you add codec support
    # if any(h["product"].lower().find("wm8960") >= 0 for h in result["hats"]):
    #     result["audio_ok"] = check_audio()

    j = json.dumps(result, indent=2)
    print(j)
    sys.stdout.flush()

    try:
        upload(result)
    except Exception as exc:
        print("upload() failed:", exc, file=sys.stderr)

    time.sleep(15)  # keep JSON on console


if __name__ == "__main__":
    main()
