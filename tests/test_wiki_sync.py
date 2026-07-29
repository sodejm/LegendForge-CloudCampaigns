"""Regression tests for deterministic source-to-Wiki mirroring."""

from __future__ import annotations

from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).parents[1] / "scripts" / "sync_wiki_docs.py"


def run_sync(
    source: Path, destination: Path, *, check: bool = False
) -> subprocess.CompletedProcess[str]:
    command = [
        sys.executable,
        str(SCRIPT),
        "--source",
        str(source),
        "--destination",
        str(destination),
    ]
    if check:
        command.append("--check")
    return subprocess.run(
        command,
        check=False,
        capture_output=True,
        text=True,
    )


def write_source(source: Path) -> None:
    nested = source / "guides"
    nested.mkdir(parents=True)
    (source / "Home.md").write_text("# Home\n", encoding="utf-8")
    (source / "_Sidebar.md").write_text(
        "[Guide](Guide.md)\n", encoding="utf-8"
    )
    (nested / "Guide.md").write_text("# Guide\n", encoding="utf-8")
    (nested / "ignored.txt").write_text(
        "not a wiki page\n", encoding="utf-8"
    )


class WikiSyncTests(unittest.TestCase):
    def test_sync_flattens_markdown_and_removes_only_managed_pages(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            source = root / "source"
            destination = root / "wiki"
            write_source(source)
            (destination / ".git").mkdir(parents=True)
            (destination / ".git" / "preserved").write_text(
                "git metadata\n", encoding="utf-8"
            )
            (destination / "assets").mkdir()
            (destination / "assets" / "logo.txt").write_text(
                "asset\n", encoding="utf-8"
            )
            (destination / "CNAME").write_text(
                "docs.example.test\n", encoding="utf-8"
            )
            (destination / "Stale.md").write_text(
                "# Stale\n", encoding="utf-8"
            )

            result = run_sync(source, destination)

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(
                (destination / "Home.md").read_text(encoding="utf-8"),
                "# Home\n",
            )
            self.assertEqual(
                (destination / "Guide.md").read_text(encoding="utf-8"),
                "# Guide\n",
            )
            self.assertEqual(
                (destination / "_Sidebar.md").read_text(encoding="utf-8"),
                "[Guide](Guide)\n",
            )
            self.assertFalse((destination / "Stale.md").exists())
            self.assertFalse((destination / "ignored.txt").exists())
            self.assertEqual(
                (destination / ".git" / "preserved").read_text(
                    encoding="utf-8"
                ),
                "git metadata\n",
            )
            self.assertEqual(
                (destination / "assets" / "logo.txt").read_text(
                    encoding="utf-8"
                ),
                "asset\n",
            )
            self.assertEqual(
                (destination / "CNAME").read_text(encoding="utf-8"),
                "docs.example.test\n",
            )

    def test_check_reports_drift_without_modifying_destination(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            source = root / "source"
            destination = root / "wiki"
            write_source(source)
            destination.mkdir()
            (destination / "Home.md").write_text(
                "# Old home\n", encoding="utf-8"
            )
            (destination / "Stale.md").write_text(
                "# Stale\n", encoding="utf-8"
            )

            result = run_sync(source, destination, check=True)

            self.assertEqual(result.returncode, 1, result.stderr)
            self.assertIn("drift detected", result.stdout)
            self.assertEqual(
                (destination / "Home.md").read_text(encoding="utf-8"),
                "# Old home\n",
            )
            self.assertTrue((destination / "Stale.md").exists())
            self.assertFalse((destination / "Guide.md").exists())

    def test_check_succeeds_for_synchronized_destination(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            source = root / "source"
            destination = root / "wiki"
            write_source(source)
            destination.mkdir()

            synchronized = run_sync(source, destination)
            result = run_sync(source, destination, check=True)

            self.assertEqual(synchronized.returncode, 0, synchronized.stderr)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("already synchronized", result.stdout)

    def test_second_sync_leaves_an_empty_git_diff(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            source = root / "source"
            destination = root / "wiki"
            write_source(source)
            destination.mkdir()
            subprocess.run(
                ["git", "init", "--quiet", str(destination)], check=True
            )

            first = run_sync(source, destination)
            self.assertEqual(first.returncode, 0, first.stderr)
            subprocess.run(
                ["git", "-C", str(destination), "add", "--all"], check=True
            )
            subprocess.run(
                [
                    "git",
                    "-C",
                    str(destination),
                    "-c",
                    "user.name=Wiki Sync Test",
                    "-c",
                    "user.email=wiki-sync@example.test",
                    "-c",
                    "commit.gpgsign=false",
                    "commit",
                    "--quiet",
                    "-m",
                    "initial wiki",
                ],
                check=True,
            )

            second = run_sync(source, destination)
            status = subprocess.run(
                ["git", "-C", str(destination), "status", "--porcelain"],
                check=True,
                capture_output=True,
                text=True,
            )

        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertIn("destination is already synchronized", second.stdout)
        self.assertEqual(status.stdout, "")


if __name__ == "__main__":
    unittest.main()
