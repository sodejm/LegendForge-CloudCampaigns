"""Discover known browser executables without relying on launch success."""
from dataclasses import dataclass
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import sys


@dataclass(frozen=True)
class Browser:
    family: str
    executable: str
    version: str


MAC_APPS = {
    "Google Chrome.app": ("Chrome", "Google Chrome"),
    "Firefox.app": ("Firefox", "firefox"),
    "Microsoft Edge.app": ("Edge", "Microsoft Edge"),
    "Opera.app": ("Opera", "Opera"),
}
LINUX_APPS = {
    "google-chrome": "Chrome", "google-chrome-stable": "Chrome",
    "chromium": "Chrome", "chromium-browser": "Chrome", "firefox": "Firefox",
    "microsoft-edge": "Edge", "opera": "Opera",
}


def discover(*, platform=None, app_roots=None, which=shutil.which, run=subprocess.run):
    platform = platform or sys.platform
    found = []
    if platform == "darwin":
        for root in app_roots or (Path("/Applications"), Path.home() / "Applications"):
            for app, (family, binary) in MAC_APPS.items():
                bundle = Path(root) / app / "Contents"
                try:
                    with (bundle / "Info.plist").open("rb") as handle:
                        version = plistlib.load(handle)["CFBundleShortVersionString"]
                    executable = bundle / "MacOS" / binary
                    if executable.is_file() and re.fullmatch(r"\d+(?:\.\d+){0,3}", version):
                        found.append(Browser(family, str(executable), version))
                except (OSError, KeyError, ValueError, TypeError):
                    continue
    elif platform.startswith("linux"):
        for name, family in LINUX_APPS.items():
            executable = which(name)
            if not executable:
                continue
            try:
                result = run([executable, "--version"], capture_output=True,
                             text=True, timeout=5, check=True)
                version = re.search(r"\b\d+(?:\.\d+){1,3}\b", result.stdout)
                if version:
                    found.append(Browser(family, executable, version.group()))
            except (OSError, subprocess.SubprocessError):
                continue
    return tuple({b.executable: b for b in found}.values())


def launch(browser, url):
    # Executable comes from discovery or explicit operator selection, never the UI.
    subprocess.Popen([browser.executable, url], stdout=subprocess.DEVNULL,
                     stderr=subprocess.DEVNULL, start_new_session=True)
