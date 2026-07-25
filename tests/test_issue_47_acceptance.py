from __future__ import annotations

import hashlib
import io
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile
import unittest


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
ARCHIVE_SCRIPT = REPOSITORY_ROOT / "scripts" / "hetzner-data-archive.sh"


class HetznerArchiveTests(unittest.TestCase):
    def run_archive(self, *arguments: object, check: bool = True) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["bash", str(ARCHIVE_SCRIPT), *(str(argument) for argument in arguments)],
            check=check,
            capture_output=True,
            text=True,
        )

    def test_backup_off_server_copy_and_restore_round_trip(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            workspace = Path(temporary)
            source = workspace / "foundry data"
            source.mkdir()
            (source / "worlds" / "campaign one").mkdir(parents=True)
            (source / "worlds" / "campaign one" / "world.json").write_text(
                '{"title":"LegendForge"}\n',
                encoding="utf-8",
            )
            (source / "assets").mkdir()
            (source / "assets" / "token image.txt").write_bytes(b"token-data\x00")

            local_archive = workspace / "foundry-data.tgz"
            self.run_archive("backup", source, local_archive)
            self.assertTrue(local_archive.is_file())
            self.assertTrue(Path(f"{local_archive}.sha256").is_file())

            off_server = workspace / "off-server"
            off_server.mkdir()
            copied_archive = off_server / local_archive.name
            shutil.copy2(local_archive, copied_archive)
            shutil.copy2(Path(f"{local_archive}.sha256"), Path(f"{copied_archive}.sha256"))

            expected_files = {
                path.relative_to(source): path.read_bytes()
                for path in source.rglob("*")
                if path.is_file()
            }
            shutil.rmtree(source)

            restored = workspace / "restored"
            restored.mkdir()
            self.run_archive("restore", copied_archive, restored)
            restored_files = {
                path.relative_to(restored): path.read_bytes()
                for path in restored.rglob("*")
                if path.is_file()
            }
            self.assertEqual(expected_files, restored_files)

    def test_backup_refuses_to_overwrite_existing_archive(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            workspace = Path(temporary)
            source = workspace / "source"
            source.mkdir()
            archive = workspace / "backup.tgz"
            archive.write_bytes(b"existing")

            result = self.run_archive("backup", source, archive, check=False)
            self.assertNotEqual(0, result.returncode)
            self.assertIn("Refusing to overwrite", result.stderr)
            self.assertEqual(b"existing", archive.read_bytes())

    def test_backup_refuses_dangling_archive_or_checksum_symlinks(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            workspace = Path(temporary)
            source = workspace / "source"
            source.mkdir()
            (source / "world.json").write_text("{}\n", encoding="utf-8")

            for suffix in ("", ".sha256"):
                with self.subTest(suffix=suffix):
                    archive = workspace / f"backup-{len(suffix)}.tgz"
                    redirected = workspace / f"redirected-{len(suffix)}.tgz"
                    Path(f"{archive}{suffix}").symlink_to(redirected)

                    result = self.run_archive("backup", source, archive, check=False)

                    self.assertNotEqual(0, result.returncode)
                    self.assertIn("Refusing to overwrite", result.stderr)
                    self.assertFalse(redirected.exists())

    def test_restore_rejects_checksum_corruption(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            workspace = Path(temporary)
            source = workspace / "source"
            source.mkdir()
            (source / "world.json").write_text("{}\n", encoding="utf-8")
            archive = workspace / "backup.tgz"
            self.run_archive("backup", source, archive)
            archive.write_bytes(archive.read_bytes() + b"corrupt")
            destination = workspace / "destination"
            destination.mkdir()

            result = self.run_archive("restore", archive, destination, check=False)
            self.assertNotEqual(0, result.returncode)
            self.assertIn("checksum verification failed", result.stderr)
            self.assertEqual([], list(destination.iterdir()))

    def test_restore_refuses_nonempty_destination(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            workspace = Path(temporary)
            source = workspace / "source"
            source.mkdir()
            (source / "world.json").write_text("{}\n", encoding="utf-8")
            archive = workspace / "backup.tgz"
            self.run_archive("backup", source, archive)
            destination = workspace / "destination"
            destination.mkdir()
            sentinel = destination / "keep.txt"
            sentinel.write_text("keep\n", encoding="utf-8")

            result = self.run_archive("restore", archive, destination, check=False)
            self.assertNotEqual(0, result.returncode)
            self.assertIn("must be empty", result.stderr)
            self.assertEqual("keep\n", sentinel.read_text(encoding="utf-8"))

    def test_restore_accepts_fresh_hetzner_bootstrap_state(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            workspace = Path(temporary)
            source = workspace / "source"
            source.mkdir()
            (source / "world.json").write_text("{}\n", encoding="utf-8")
            archive = workspace / "backup.tgz"
            self.run_archive("backup", source, archive)
            destination = workspace / "destination"
            destination.mkdir()
            (destination / ".formatted").touch()
            (destination / "lost+found").mkdir()

            self.run_archive("restore", archive, destination)

            self.assertEqual(
                "{}\n",
                (destination / "world.json").read_text(encoding="utf-8"),
            )
            self.assertTrue((destination / ".formatted").is_file())

    def test_quarantine_and_restore_post_bootstrap_foundry_data(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            workspace = Path(temporary)
            source = workspace / "source"
            source.mkdir()
            (source / "Data" / "worlds").mkdir(parents=True)
            (source / "Data" / "worlds" / "restored.json").write_text(
                '{"restored":true}\n',
                encoding="utf-8",
            )
            archive = workspace / "backup.tgz"
            self.run_archive("backup", source, archive)

            destination = workspace / "destination"
            destination.mkdir()
            (destination / ".formatted").touch()
            (destination / "lost+found").mkdir()
            (destination / "Config").mkdir()
            (destination / "Config" / "options.json").write_text(
                '{"bootstrap":true}\n',
                encoding="utf-8",
            )
            (destination / "Logs").mkdir()

            result = self.run_archive("quarantine", destination)
            quarantine = next(destination.glob(".restore-quarantine.*"))
            self.assertIn(str(quarantine), result.stdout)
            self.assertEqual(
                '{"bootstrap":true}\n',
                (quarantine / "Config" / "options.json").read_text(encoding="utf-8"),
            )

            self.run_archive("restore", archive, destination)

            self.assertEqual(
                '{"restored":true}\n',
                (destination / "Data" / "worlds" / "restored.json").read_text(
                    encoding="utf-8",
                ),
            )
            self.assertTrue((quarantine / "Logs").is_dir())

            post_restore_archive = workspace / "post-restore.tgz"
            self.run_archive("backup", destination, post_restore_archive)
            second_destination = workspace / "second-destination"
            second_destination.mkdir()
            self.run_archive("restore", post_restore_archive, second_destination)
            self.assertEqual(
                '{"restored":true}\n',
                (
                    second_destination / "Data" / "worlds" / "restored.json"
                ).read_text(encoding="utf-8"),
            )
            self.assertEqual(
                [],
                list(second_destination.glob(".restore-quarantine.*")),
            )

    def test_restore_rejects_path_traversal(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            workspace = Path(temporary)
            archive = workspace / "unsafe.tgz"
            payload = b"escape"
            with tarfile.open(archive, "w:gz") as bundle:
                member = tarfile.TarInfo("../escape.txt")
                member.size = len(payload)
                bundle.addfile(member, io.BytesIO(payload))
            checksum = hashlib.sha256(archive.read_bytes()).hexdigest()
            Path(f"{archive}.sha256").write_text(
                f"{checksum}  {archive.name}\n",
                encoding="utf-8",
            )
            destination = workspace / "destination"
            destination.mkdir()

            result = self.run_archive("restore", archive, destination, check=False)
            self.assertNotEqual(0, result.returncode)
            self.assertIn("Unsafe archive member", result.stderr)
            self.assertFalse((workspace / "escape.txt").exists())

    def test_restore_rejects_links_before_quarantine_can_be_overwritten(self) -> None:
        for link_type in (tarfile.SYMTYPE, tarfile.LNKTYPE):
            with self.subTest(link_type=link_type), tempfile.TemporaryDirectory() as temporary:
                workspace = Path(temporary)
                archive = workspace / "unsafe-link.tgz"
                quarantine_name = ".restore-quarantine.rollback"
                payload = b"overwritten"

                with tarfile.open(archive, "w:gz") as bundle:
                    link = tarfile.TarInfo("pivot")
                    link.type = link_type
                    link.linkname = quarantine_name
                    bundle.addfile(link)

                    member = tarfile.TarInfo("pivot/protected.txt")
                    member.size = len(payload)
                    bundle.addfile(member, io.BytesIO(payload))

                checksum = hashlib.sha256(archive.read_bytes()).hexdigest()
                Path(f"{archive}.sha256").write_text(
                    f"{checksum}  {archive.name}\n",
                    encoding="utf-8",
                )

                destination = workspace / "destination"
                destination.mkdir()
                quarantine = destination / quarantine_name
                quarantine.mkdir()
                protected = quarantine / "protected.txt"
                protected.write_text("keep\n", encoding="utf-8")

                result = self.run_archive("restore", archive, destination, check=False)

                self.assertNotEqual(0, result.returncode)
                self.assertIn("unsupported link type", result.stderr)
                self.assertEqual("keep\n", protected.read_text(encoding="utf-8"))
                self.assertFalse((destination / "pivot").exists())


class Issue47DocumentationTests(unittest.TestCase):
    def read(self, relative_path: str) -> str:
        return (REPOSITORY_ROOT / relative_path).read_text(encoding="utf-8")

    def test_required_navigation_links_are_present(self) -> None:
        index = self.read("DOCUMENTATION_INDEX.md")
        comparison = self.read("docs/DEPLOYMENT_MODEL_COMPARISON.md")
        sidebar = self.read("wiki/_Sidebar.md")

        self.assertIn(
            "[Deployment model comparison](docs/DEPLOYMENT_MODEL_COMPARISON.md)",
            index,
        )
        self.assertIn(
            "[Hetzner deployment guide](infrastructure/deployments/hetzner/README.md)",
            index,
        )
        self.assertIn(
            "[Hetzner deployment README](../infrastructure/deployments/hetzner/README.md)",
            comparison,
        )
        self.assertIn(
            "docs/DEPLOYMENT_MODEL_COMPARISON.md",
            sidebar,
        )
        self.assertIn(
            "infrastructure/deployments/hetzner/README.md",
            sidebar,
        )

    def test_dangerous_lifecycle_guidance_is_removed(self) -> None:
        root_readme = self.read("README.md")
        comparison = self.read("docs/DEPLOYMENT_MODEL_COMPARISON.md")
        wiki_how_to = self.read("wiki/How-To.md")
        deployment_variables = self.read("infrastructure/deployments/hetzner/variables.tf")
        module_variables = self.read("infrastructure/modules/providers/hetzner/variables.tf")

        self.assertNotIn("hcloud volume create-backup", root_readme)
        self.assertNotIn("All platforms support spin-down", root_readme)
        self.assertNotIn("Daily snapshots via AWS Backup", root_readme)
        self.assertNotIn("Daily snapshots via Disk Resource Policy", root_readme)
        self.assertNotIn("Disk snapshot policy and managed DB", comparison)
        self.assertIn("deletes both the server and its managed data volume", comparison)
        self.assertIn("deletes the server and managed data volume", wiki_how_to)
        self.assertIn("deletes the server and managed data volume", deployment_variables)
        self.assertIn("deletes the server and managed data volume", module_variables)

    def test_hetzner_guide_covers_all_issue_47_operating_topics(self) -> None:
        guide = self.read("infrastructure/deployments/hetzner/README.md")

        for required_heading in (
            "### Temporary game-session scaling",
            "## Operational limits and trade-offs",
            "## Migration path to AWS, Azure, or GCP",
        ):
            with self.subTest(required_heading=required_heading):
                self.assertIn(required_heading, guide)

        self.assertIn("**Data residency:**", guide)
        self.assertIn("**Support:**", guide)
        self.assertIn("Server Backups and Snapshots cover only the server's boot disk", guide)
        self.assertIn("docker compose stop foundry", guide)
        self.assertIn("bash -s -- quarantine /opt/foundry/data", guide)
        self.assertIn('backup_dir="/root/foundry-backups"', guide)
        self.assertIn("sudo resize2fs", guide)
        self.assertIn("this module does not grow an existing ext4 filesystem", guide)
        self.assertIn("official Volume resize procedure", guide)

        for provider in ("AWS deployment", "Azure deployment", "GCP deployment"):
            with self.subTest(provider=provider):
                self.assertIn(provider, guide)

        for comparison_category in (
            "| **Availability** |",
            "| **Database** |",
            "| **Backup** |",
            "| **Monitoring** |",
        ):
            with self.subTest(comparison_category=comparison_category):
                self.assertIn(comparison_category, guide)


if __name__ == "__main__":
    unittest.main()
