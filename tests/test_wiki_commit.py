"""Functional tests for committing synchronized Wiki changes."""

from __future__ import annotations

import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).parents[1] / "scripts" / "commit_wiki_changes.py"
SOURCE_SHA = "0123456789abcdef0123456789abcdef01234567"
BOT_NAME = "github-actions[bot]"
BOT_EMAIL = "41898282+github-actions[bot]@users.noreply.github.com"


def git(repository: Path, *arguments: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(repository), *arguments],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout


def initialize_repository(
    repository: Path, files: dict[str, str] | None = None
) -> str:
    repository.mkdir()
    subprocess.run(["git", "init", "--quiet", str(repository)], check=True)
    for name, content in (files or {"Home.md": "# Home\n"}).items():
        (repository / name).write_text(content, encoding="utf-8")
    git(repository, "add", "--all")
    git(
        repository,
        "-c",
        "user.name=Initial Author",
        "-c",
        "user.email=initial@example.test",
        "-c",
        "commit.gpgSign=false",
        "commit",
        "--quiet",
        "-m",
        "initial wiki",
    )
    return git(repository, "rev-parse", "HEAD").strip()


def run_commit(
    repository: Path,
    output: Path | None = None,
    environment: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:
    command = [
        sys.executable,
        str(SCRIPT),
        "--repository",
        str(repository),
        "--source-sha",
        SOURCE_SHA,
    ]
    if output is not None:
        command.extend(["--output", str(output)])
    return subprocess.run(
        command,
        check=False,
        capture_output=True,
        text=True,
        env=environment,
    )


class WikiCommitTests(unittest.TestCase):
    def test_unchanged_repository_succeeds_without_a_commit(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            repository = root / "wiki"
            initial_sha = initialize_repository(repository)
            output = root / "github-output"

            result = run_commit(repository, output)

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("no changes to commit", result.stdout)
            self.assertEqual(
                git(repository, "rev-parse", "HEAD").strip(), initial_sha
            )
            self.assertEqual(git(repository, "status", "--porcelain"), "")
            self.assertEqual(
                output.read_text(encoding="utf-8"),
                "committed=false\ncommit-sha=\n",
            )

    def test_untracked_page_is_staged_and_committed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            repository = Path(temporary_directory) / "wiki"
            initialize_repository(repository)
            (repository / "Guide.md").write_text(
                "# Guide\n", encoding="utf-8"
            )

            result = run_commit(repository)

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(
                git(repository, "show", "--format=", "--name-status", "HEAD"),
                "A\tGuide.md\n",
            )
            self.assertEqual(git(repository, "status", "--porcelain"), "")

    def test_modified_and_deleted_pages_are_committed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            repository = Path(temporary_directory) / "wiki"
            initialize_repository(
                repository,
                {"Home.md": "# Home\n", "Stale.md": "# Stale\n"},
            )
            (repository / "Home.md").write_text(
                "# Updated home\n", encoding="utf-8"
            )
            (repository / "Stale.md").unlink()

            result = run_commit(repository)

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(
                git(
                    repository,
                    "show",
                    "--format=",
                    "--name-status",
                    "HEAD",
                ).splitlines(),
                ["M\tHome.md", "D\tStale.md"],
            )
            self.assertEqual(git(repository, "status", "--porcelain"), "")

    def test_commit_uses_bot_identity_and_source_sha_message(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            repository = root / "wiki"
            initialize_repository(repository)
            (repository / "Home.md").write_text(
                "# Updated home\n", encoding="utf-8"
            )
            output = root / "github-output"
            environment = os.environ.copy()
            environment.update(
                {
                    "GIT_AUTHOR_NAME": "Untrusted Author",
                    "GIT_AUTHOR_EMAIL": "untrusted-author@example.test",
                    "GIT_COMMITTER_NAME": "Untrusted Committer",
                    "GIT_COMMITTER_EMAIL": "untrusted-committer@example.test",
                }
            )

            result = run_commit(repository, output, environment)

            self.assertEqual(result.returncode, 0, result.stderr)
            metadata = git(
                repository,
                "show",
                "-s",
                "--format=%an%n%ae%n%cn%n%ce%n%B",
                "HEAD",
            )
            self.assertEqual(
                metadata.splitlines(),
                [
                    BOT_NAME,
                    BOT_EMAIL,
                    BOT_NAME,
                    BOT_EMAIL,
                    f"docs: synchronize from {SOURCE_SHA}",
                    "",
                ],
            )
            commit_sha = git(repository, "rev-parse", "HEAD").strip()
            self.assertEqual(
                output.read_text(encoding="utf-8"),
                f"committed=true\ncommit-sha={commit_sha}\n",
            )


if __name__ == "__main__":
    unittest.main()
