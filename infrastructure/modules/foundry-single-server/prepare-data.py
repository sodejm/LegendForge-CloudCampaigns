#!/usr/bin/env python3
"""Mount one explicitly identified data disk; never fall back to the boot disk."""

import json
import os
from pathlib import Path
import stat
import subprocess
import sys
import time


def run(*args):
    return subprocess.run(args, check=True, capture_output=True, text=True).stdout


def prepare(device, destination, attempts=60):
    target = Path(destination)
    for attempt in range(attempts):
        if Path(device).exists():
            break
        if attempt == attempts - 1:
            raise RuntimeError("Data disk did not arrive; refusing to start Foundry")
        time.sleep(5)
    if not stat.S_ISBLK(os.stat(device).st_mode):
        raise RuntimeError("Data device is not a block device")

    disks = json.loads(run("lsblk", "--json", "--output", "PATH,TYPE,FSTYPE,MOUNTPOINTS", device))["blockdevices"]
    if len(disks) != 1 or disks[0]["type"] != "disk" or disks[0].get("children"):
        raise RuntimeError("Expected one whole, unpartitioned data disk")
    disk = disks[0]
    mounts = [path for path in disk.get("mountpoints", []) if path]
    if mounts:
        if mounts != [str(target)] or disk.get("fstype") != "ext4":
            raise RuntimeError("Data disk is mounted elsewhere or has an unexpected filesystem")
        return
    if target.is_mount():
        raise RuntimeError("Another filesystem occupies the data directory")
    if target.exists() and any(target.iterdir()):
        raise RuntimeError("Unmounted data directory is not empty")

    # A failed probe aborts. Only a successful empty signature inventory may format.
    signatures = json.loads(run("wipefs", "--no-act", "--json", device))["signatures"]
    if not signatures and not disk.get("fstype"):
        run("mkfs.ext4", "-F", device)
    elif disk.get("fstype") != "ext4" or not signatures or any(s["type"] != "ext4" for s in signatures):
        raise RuntimeError("Unknown data disk contents; refusing to format")
    target.mkdir(parents=True, exist_ok=True)
    run("mount", "-o", "nodev,nosuid", device, str(target))
    # This is reached only after mount succeeds, never on an unmounted directory.
    os.chown(target, 1000, 1000)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("Usage: prepare-data.py DEVICE DIRECTORY")
    prepare(sys.argv[1], sys.argv[2])
