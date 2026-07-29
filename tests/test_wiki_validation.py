"""Regression tests for the local-only Wiki source preflight."""

from __future__ import annotations

from contextlib import redirect_stderr
import importlib.util
import io
from pathlib import Path
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).parents[1] / "scripts" / "validate_wiki_docs.py"
SPEC = importlib.util.spec_from_file_location("validate_wiki_docs", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
wiki_validation = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = wiki_validation
SPEC.loader.exec_module(wiki_validation)


def write_wiki(source: Path, *, sidebar: str = "[[Guide]]") -> None:
    (source / "Home.md").write_text("# Home\n", encoding="utf-8")
    (source / "Guide.md").write_text("# Guide\n", encoding="utf-8")
    (source / "_Sidebar.md").write_text(sidebar, encoding="utf-8")


class WikiValidationTests(unittest.TestCase):
    def run_validation(self, source: Path) -> tuple[int, str]:
        errors = io.StringIO()
        with redirect_stderr(errors):
            result = wiki_validation.main(["--source", str(source)])
        return result, errors.getvalue()

    def test_valid_source_requires_no_wiki_checkout(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            source = Path(temporary_directory)
            write_wiki(source)
            result, errors = self.run_validation(source)

        self.assertEqual(result, 0)
        self.assertEqual(errors, "")

    def test_repository_wiki_source_is_valid(self) -> None:
        source = Path(__file__).parents[1] / "wiki"

        result, errors = self.run_validation(source)

        self.assertEqual(result, 0)
        self.assertEqual(errors, "")

    def test_missing_home_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            source = Path(temporary_directory)
            (source / "_Sidebar.md").write_text("", encoding="utf-8")
            result, errors = self.run_validation(source)

        self.assertEqual(result, 1)
        self.assertIn("required page is missing: Home.md", errors)

    def test_sidebar_targets_must_exist(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            source = Path(temporary_directory)
            write_wiki(source, sidebar="[[Guide]]\n[Missing](Missing.md)")
            result, errors = self.run_validation(source)

        self.assertEqual(result, 1)
        self.assertIn("broken sidebar target: Missing.md", errors)

    def test_duplicate_page_names_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            source = Path(temporary_directory)
            write_wiki(source)
            (source / "nested").mkdir()
            (source / "nested" / "Guide.md").write_text(
                "# nested guide\n", encoding="utf-8"
            )
            result, errors = self.run_validation(source)

        self.assertEqual(result, 1)
        self.assertIn(
            "duplicate wiki page name: Guide.md and nested/Guide.md", errors
        )

    def test_case_insensitive_filename_collisions_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            source = Path(temporary_directory)
            errors = wiki_validation._source_errors(
                source,
                [source / "Home.md", source / "Guide.md", source / "guide.md"],
            )

        self.assertEqual(
            [error.message for error in errors],
            [
                "case-insensitive filename collision: Guide.md and guide.md",
                "duplicate wiki page name: Guide.md and guide.md",
            ],
        )

    def test_unsafe_sidebar_paths_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            source = Path(temporary_directory)
            write_wiki(
                source,
                sidebar=(
                    "[[../Secret]]\n"
                    "[Etc](/etc/passwd)\n"
                    "[Drive](C:/secret)"
                ),
            )
            result, errors = self.run_validation(source)

        self.assertEqual(result, 1)
        self.assertIn("unsafe sidebar target: ../Secret", errors)
        self.assertIn("unsafe sidebar target: /etc/passwd", errors)
        self.assertIn("unsafe sidebar target: C:/secret", errors)

    def test_symlinked_sources_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            source = Path(temporary_directory)
            write_wiki(source)
            outside = source.parent / f"{source.name}-outside.md"
            outside.write_text("# Outside\n", encoding="utf-8")
            try:
                (source / "linked.md").symlink_to(outside)
                result, errors = self.run_validation(source)
            finally:
                outside.unlink(missing_ok=True)

        self.assertEqual(result, 1)
        self.assertIn("symlinked source is not supported: linked.md", errors)


if __name__ == "__main__":
    unittest.main()
