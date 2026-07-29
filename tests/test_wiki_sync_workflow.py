"""Contract checks for the workflow that publishes validated Wiki source."""

from __future__ import annotations

from pathlib import Path
import unittest


WORKFLOW = (
    Path(__file__).parents[1] / ".github" / "workflows" / "sync-wiki.yml"
)


class WikiSyncWorkflowTests(unittest.TestCase):
    def test_workflow_commits_only_changed_wiki_content(self) -> None:
        workflow = WORKFLOW.read_text(encoding="utf-8")

        self.assertIn("python scripts/sync_wiki_docs.py", workflow)
        self.assertIn("--source wiki", workflow)
        self.assertIn('--destination "$WIKI_WORKTREE"', workflow)
        self.assertIn("python scripts/commit_wiki_changes.py", workflow)
        self.assertIn('--repository "$WIKI_WORKTREE"', workflow)
        self.assertIn('--source-sha "$SOURCE_SHA"', workflow)
        self.assertIn('--output "$GITHUB_OUTPUT"', workflow)
        self.assertIn(
            "if: steps.wiki_commit.outputs.committed == 'true'", workflow
        )
        commit_step = workflow.split(
            "- name: Commit Wiki changes", maxsplit=1
        )[1].split("- name: Push Wiki changes", maxsplit=1)[0]
        self.assertNotIn("GITHUB_TOKEN", commit_step)
        self.assertNotIn("git commit", workflow)
        self.assertNotIn("git config user.", workflow)
        self.assertIn("GITHUB_TOKEN: ${{ github.token }}", workflow)
        self.assertIn("http.https://github.com/.extraheader", workflow)
        self.assertIn("push origin HEAD:master", workflow)

    def test_workflow_is_serialized_and_never_force_pushes(self) -> None:
        workflow = WORKFLOW.read_text(encoding="utf-8")

        self.assertIn("concurrency:", workflow)
        self.assertIn("cancel-in-progress: false", workflow)
        self.assertNotIn("--force", workflow)
        self.assertNotIn("force-with-lease", workflow)

    def test_workflow_publishes_only_reviewed_main_source(self) -> None:
        workflow = WORKFLOW.read_text(encoding="utf-8")

        self.assertIn("branches: [main]", workflow)
        self.assertIn('- "wiki/**"', workflow)
        self.assertNotIn("pull_request:", workflow)
        self.assertIn("persist-credentials: false", workflow)
        self.assertIn("permissions: {}", workflow)
        self.assertIn("contents: write", workflow)
        self.assertIn(
            "sodejm/LegendForge-CloudCampaigns.wiki.git", workflow
        )


if __name__ == "__main__":
    unittest.main()
