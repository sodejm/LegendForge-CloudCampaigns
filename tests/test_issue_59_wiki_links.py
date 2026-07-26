from __future__ import annotations

from pathlib import Path
import re
import unittest
from urllib.parse import unquote, urlsplit


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
WIKI_ROOT = REPOSITORY_ROOT / "wiki"
PUBLISHED_WIKI_BASE = "https://github.com/sodejm/LegendForge-CloudCampaigns/wiki"
REPOSITORY_BLOB_BASE = (
    "https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/"
)
WIKI_PAGE_FILES = (
    "Home.md",
    "Quickstart.md",
    "Installation.md",
    "Provider-Guide.md",
    "How-To.md",
    "Prompts.md",
    "Use-Cases.md",
    "Architecture-and-Security.md",
)
PUBLISHABLE_WIKI_FILES = (*WIKI_PAGE_FILES, "_Sidebar.md")
MARKDOWN_LINK = re.compile(r"(?<!!)\[[^\]]+\]\(([^)]+)\)")


def link_targets(path: Path) -> list[str]:
    return [
        target.strip()
        for target in MARKDOWN_LINK.findall(path.read_text(encoding="utf-8"))
    ]


class Issue59WikiNavigationTests(unittest.TestCase):
    def test_repository_relative_links_resolve(self) -> None:
        sources = (
            REPOSITORY_ROOT / "README.md",
            REPOSITORY_ROOT / "DOCUMENTATION_INDEX.md",
            *sorted(WIKI_ROOT.glob("*.md")),
        )

        for source in sources:
            for target in link_targets(source):
                parsed = urlsplit(target)
                if parsed.scheme or target.startswith("#"):
                    continue

                relative_path = unquote(parsed.path)
                if not relative_path:
                    continue

                resolved = (source.parent / relative_path).resolve()
                with self.subTest(source=source.relative_to(REPOSITORY_ROOT), target=target):
                    self.assertTrue(
                        resolved.exists(),
                        f"{source.relative_to(REPOSITORY_ROOT)} links to missing {target}",
                    )

    def test_publishable_pages_avoid_repository_only_or_extensionless_links(self) -> None:
        page_names = set(WIKI_PAGE_FILES)
        page_slugs = {Path(name).stem for name in WIKI_PAGE_FILES}

        for filename in PUBLISHABLE_WIKI_FILES:
            source = WIKI_ROOT / filename
            for target in link_targets(source):
                parsed = urlsplit(target)
                if parsed.scheme:
                    continue

                local_name = Path(unquote(parsed.path)).name
                with self.subTest(source=filename, target=target):
                    self.assertNotIn(
                        local_name,
                        page_names,
                        "publishable wiki pages must not use repository-only .md links",
                    )
                    self.assertNotIn(
                        local_name,
                        page_slugs,
                        "extensionless wiki links break in the repository source view",
                    )

    def test_published_wiki_links_name_known_pages(self) -> None:
        page_slugs = {Path(name).stem for name in WIKI_PAGE_FILES}

        for filename in PUBLISHABLE_WIKI_FILES:
            source = WIKI_ROOT / filename
            for target in link_targets(source):
                if not target.startswith(f"{PUBLISHED_WIKI_BASE}/"):
                    continue

                slug = unquote(urlsplit(target).path).removeprefix(
                    "/sodejm/LegendForge-CloudCampaigns/wiki/"
                )
                with self.subTest(source=filename, target=target):
                    self.assertIn(slug, page_slugs)

    def test_wiki_repository_links_name_existing_paths(self) -> None:
        for source in sorted(WIKI_ROOT.glob("*.md")):
            for target in link_targets(source):
                if not target.startswith(REPOSITORY_BLOB_BASE):
                    continue

                relative_path = unquote(
                    urlsplit(target.removeprefix(REPOSITORY_BLOB_BASE)).path
                )
                with self.subTest(
                    source=source.relative_to(REPOSITORY_ROOT), target=target
                ):
                    self.assertTrue(
                        (REPOSITORY_ROOT / relative_path).exists(),
                        f"{source.relative_to(REPOSITORY_ROOT)} links to missing {target}",
                    )

    def test_sidebar_links_every_published_page(self) -> None:
        sidebar_targets = set(link_targets(WIKI_ROOT / "_Sidebar.md"))
        expected_targets = {
            f"{PUBLISHED_WIKI_BASE}/{Path(filename).stem}"
            for filename in WIKI_PAGE_FILES
        }
        self.assertLessEqual(expected_targets, sidebar_targets)

    def test_source_index_explains_dual_navigation_and_publication(self) -> None:
        source_index = (WIKI_ROOT / "README.md").read_text(encoding="utf-8")

        for filename in (*WIKI_PAGE_FILES, "_Sidebar.md"):
            with self.subTest(filename=filename):
                self.assertIn(f"]({filename})", source_index)

        self.assertIn(f"]({PUBLISHED_WIKI_BASE})", source_index)
        self.assertIn("does not update the published wiki by itself", source_index)
        self.assertIn("Do not use extensionless relative targets", source_index)

    def test_repository_entry_points_offer_source_and_published_navigation(self) -> None:
        for filename in ("README.md", "DOCUMENTATION_INDEX.md"):
            document = (REPOSITORY_ROOT / filename).read_text(encoding="utf-8")
            with self.subTest(filename=filename):
                self.assertIn(f"]({PUBLISHED_WIKI_BASE})", document)
                self.assertIn("](wiki/README.md)", document)


if __name__ == "__main__":
    unittest.main()
