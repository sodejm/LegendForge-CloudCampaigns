"""Regression tests for GitHub Wiki UI link rendering."""

from __future__ import annotations

import importlib.util
import tempfile
from pathlib import Path
import sys
import unittest


SCRIPT = Path(__file__).parents[1] / "scripts" / "rewrite_wiki_links.py"
SPEC = importlib.util.spec_from_file_location("rewrite_wiki_links", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
wiki_links = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = wiki_links
SPEC.loader.exec_module(wiki_links)


class WikiLinkRewriteTests(unittest.TestCase):
    def test_local_markdown_links_use_wiki_page_targets(self) -> None:
        markdown = (
            "[Threat model](Architecture-and-Security.md)\n"
            "[Providers](Provider-Guide.md#aws)\n"
        )

        self.assertEqual(
            wiki_links.rewrite_wiki_links(markdown),
            (
                "[Threat model](Architecture-and-Security)\n"
                "[Providers](Provider-Guide#aws)\n"
            ),
        )

    def test_non_page_targets_are_preserved(self) -> None:
        markdown = (
            "[External](https://example.com/Guide.md)\n"
            "![Diagram](Architecture-and-Security.md)\n"
            "[Section](#release-decision)\n"
            "[Email](mailto:docs@example.com)\n"
        )

        self.assertEqual(wiki_links.rewrite_wiki_links(markdown), markdown)

    def test_code_examples_are_preserved(self) -> None:
        markdown = (
            "Use `[Guide](How-To.md)` as the source form.\n"
            "```markdown\n"
            "[Guide](How-To.md)\n"
            "```\n"
            "Navigate with [Guide](How-To.md).\n"
        )

        self.assertEqual(
            wiki_links.rewrite_wiki_links(markdown),
            (
                "Use `[Guide](How-To.md)` as the source form.\n"
                "```markdown\n"
                "[Guide](How-To.md)\n"
                "```\n"
                "Navigate with [Guide](How-To).\n"
            ),
        )

    def test_directory_rewrite_updates_only_regular_markdown_pages(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            wiki = Path(temporary_directory)
            page = wiki / "_Sidebar.md"
            page.write_text("[Guide](How-To.md)\n", encoding="utf-8")
            asset = wiki / "asset.txt"
            asset.write_text("[Guide](How-To.md)\n", encoding="utf-8")

            wiki_links.rewrite_wiki_directory(wiki)

            self.assertEqual(
                page.read_text(encoding="utf-8"), "[Guide](How-To)\n"
            )
            self.assertEqual(
                asset.read_text(encoding="utf-8"), "[Guide](How-To.md)\n"
            )


if __name__ == "__main__":
    unittest.main()
