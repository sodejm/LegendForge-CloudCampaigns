"""Exercise disk bootstrap decisions without touching any real block device."""

import importlib.util
import json
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "prepare_data", ROOT / "infrastructure/modules/foundry-single-server/prepare-data.py"
)
disk = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(disk)


class PrepareDataTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.device = Path(self.tmp.name) / "device"
        self.device.touch()
        self.target = Path(self.tmp.name) / "data"
        self.commands = []
        self.info = {"type": "disk", "fstype": None, "mountpoints": [None]}
        self.signatures = []
        self.failure = None
        self.chown = self.enterContext(patch.object(disk.os, "chown"))
        self.enterContext(patch.object(disk.stat, "S_ISBLK", return_value=True))
        self.enterContext(patch.object(disk, "run", side_effect=self.run_command))

    def run_command(self, *args):
        self.commands.append(args)
        if args[0] == self.failure:
            raise subprocess.CalledProcessError(1, args)
        if args[0] == "lsblk":
            return json.dumps({"blockdevices": [self.info]})
        if args[0] == "wipefs":
            return json.dumps({"signatures": self.signatures})
        return ""

    def prepare(self):
        disk.prepare(str(self.device), str(self.target), attempts=1)

    def assert_no_format(self):
        self.assertNotIn("mkfs.ext4", [command[0] for command in self.commands])

    def test_blank_disk_is_formatted_then_mounted_before_ownership(self):
        self.prepare()
        self.assertEqual([c[0] for c in self.commands], ["lsblk", "wipefs", "mkfs.ext4", "mount"])
        self.assertEqual(self.commands[-1][-2:], (str(self.device), str(self.target)))
        self.chown.assert_called_once_with(self.target, 1000, 1000)

    def test_existing_ext4_is_never_formatted(self):
        self.info["fstype"] = "ext4"
        self.signatures = [{"type": "ext4"}]
        self.prepare()
        self.assert_no_format()
        self.assertEqual(self.commands[-1][0], "mount")

    def test_probe_failure_never_formats_or_mounts(self):
        self.failure = "wipefs"
        with self.assertRaises(subprocess.CalledProcessError):
            self.prepare()
        self.assert_no_format()
        self.chown.assert_not_called()

    def test_unknown_signature_is_preserved(self):
        self.signatures = [{"type": "LVM2_member"}]
        with self.assertRaisesRegex(RuntimeError, "Unknown"):
            self.prepare()
        self.assert_no_format()

    def test_partitioned_disk_is_preserved(self):
        self.info["children"] = [{"type": "part"}]
        with self.assertRaisesRegex(RuntimeError, "unpartitioned"):
            self.prepare()
        self.assert_no_format()

    def test_root_disk_is_refused(self):
        self.info["mountpoints"] = ["/"]
        with self.assertRaisesRegex(RuntimeError, "elsewhere"):
            self.prepare()
        self.assert_no_format()

    def test_missing_disk_cannot_use_root_directory(self):
        self.device.unlink()
        with self.assertRaisesRegex(RuntimeError, "did not arrive"):
            self.prepare()
        self.assertEqual(self.commands, [])
        self.assertFalse(self.target.exists())

    def test_mount_failure_does_not_change_directory_ownership(self):
        self.failure = "mount"
        with self.assertRaises(subprocess.CalledProcessError):
            self.prepare()
        self.chown.assert_not_called()

    def test_already_mounted_data_is_reused(self):
        self.info.update(fstype="ext4", mountpoints=[str(self.target)])
        self.prepare()
        self.assertEqual([c[0] for c in self.commands], ["lsblk"])
        self.chown.assert_not_called()

    def test_nonempty_unmounted_directory_is_preserved(self):
        self.target.mkdir()
        (self.target / "world.db").write_text("preserve")
        with self.assertRaisesRegex(RuntimeError, "not empty"):
            self.prepare()
        self.assert_no_format()


if __name__ == "__main__":
    unittest.main()
