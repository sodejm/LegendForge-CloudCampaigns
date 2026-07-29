# Wiki synchronization operations and recovery

The Markdown files under `wiki/` are the canonical source for the LegendForge
GitHub Wiki. The `Sync Wiki` workflow publishes them to the separate
`sodejm/LegendForge-CloudCampaigns.wiki.git` repository. Direct edits to
managed Wiki pages are temporary: the next successful synchronization restores
the reviewed source.

For the managed-file rules and page map, see the
[Wiki synchronization design](WIKI_SYNC.md).

## Automatic publication

A push to `main` that changes `wiki/**` starts publication automatically:

1. Make Wiki changes on a dedicated branch.
2. Run the local validation and tests.
3. Merge the reviewed pull request into `main`.
4. Verify the `Sync Wiki` run and resulting Wiki commit.

Changes only to the workflow or synchronization scripts do not match the Wiki
source path filter. Dispatch the workflow manually after those changes reach
`main`.

## Local validation

Validation does not need a Wiki checkout or network access:

```console
python scripts/validate_wiki_docs.py --source wiki
python -m unittest discover -s tests -p "test_wiki_*.py"
python -m unittest tests.test_issue_59_wiki_links
```

To test the full mirror, clone the initialized Wiki and synchronize into that
checkout:

```console
verification_root="$(mktemp -d)"
wiki_checkout="$verification_root/LegendForge-CloudCampaigns.wiki"
git clone --depth=2 \
  https://github.com/sodejm/LegendForge-CloudCampaigns.wiki.git \
  "$wiki_checkout"
python scripts/sync_wiki_docs.py \
  --source wiki \
  --destination "$wiki_checkout" \
  --check
```

Check mode does not modify the checkout. It exits zero when synchronized and
one when drift exists. To review the exact changes, rerun without `--check`,
inspect `git -C "$wiki_checkout" status --short` and the diff, then discard the
temporary checkout. A second sync must report that the destination is already
synchronized.

## Manual dispatch

Always dispatch operational publication from `main`:

```console
gh workflow run sync-wiki.yml \
  --repo sodejm/LegendForge-CloudCampaigns \
  --ref main
```

Find and watch the newest manual run:

```console
run_id="$(gh run list \
  --repo sodejm/LegendForge-CloudCampaigns \
  --workflow sync-wiki.yml \
  --branch main \
  --event workflow_dispatch \
  --limit 1 \
  --json databaseId \
  --jq '.[0].databaseId')"
gh run watch "$run_id" \
  --repo sodejm/LegendForge-CloudCampaigns \
  --compact \
  --exit-status
```

Do not dispatch a feature branch: that can publish content which has not been
reviewed or merged.

## Verify a publication

Record the source SHA, workflow run URL, and resulting Wiki commit SHA in the
issue or pull request evidence.

1. Confirm the run completed successfully at the intended `main` SHA:

   ```console
   gh run view "$run_id" \
     --repo sodejm/LegendForge-CloudCampaigns \
     --json conclusion,event,headSha,jobs,url
   ```

2. Clone the Wiki and inspect its newest commit:

   ```console
   git -C "$wiki_checkout" show --no-patch \
     --format='%H%n%an <%ae>%n%s' HEAD
   ```

   The author must be `github-actions[bot]`, and the subject must be
   `docs: synchronize from <source-sha>`.

3. Rerun the local mirror. It must report that the destination is synchronized,
   and `git status --porcelain` must print nothing.
4. Open the
   [published Wiki](https://github.com/sodejm/LegendForge-CloudCampaigns/wiki),
   follow every sidebar entry, and confirm headings and links render correctly.

## No-op verification

An unchanged manual run must not create a Wiki commit. Record the Wiki tip
before and after the run:

```console
before="$(git ls-remote \
  https://github.com/sodejm/LegendForge-CloudCampaigns.wiki.git \
  refs/heads/master | awk '{print $1}')"
# Dispatch main and wait for the run here.
after="$(git ls-remote \
  https://github.com/sodejm/LegendForge-CloudCampaigns.wiki.git \
  refs/heads/master | awk '{print $1}')"
test "$before" = "$after"
```

If the tips differ, inspect the Wiki log before deciding whether another writer
or a real source change caused the new commit.

## Authentication and concurrency failures

`Repository not found` during clone or HTTP 403 during push usually means the
Wiki is disabled, uninitialized, or the job token lacks `contents: write`.
Confirm:

```console
gh api repos/sodejm/LegendForge-CloudCampaigns \
  --jq '{has_wiki,visibility}'
git ls-remote \
  https://github.com/sodejm/LegendForge-CloudCampaigns.wiki.git \
  refs/heads/master
```

The workflow concurrency group serializes publication. An external writer can
still update `master` after clone and before push; the push then correctly
fails as non-fast-forward. Never force push the Wiki. Inspect the intervening
commit, wait for the writer, and dispatch `main` again.

Never put a token in a clone URL, command transcript, issue, or artifact. Do
not substitute a long-lived personal token to bypass repository policy.

## Rollback

Rollback through canonical source, not by rewriting Wiki history:

1. Create a branch from current `origin/main`.
2. Revert or restore the affected files under `wiki/`.
3. Run local validation and tests.
4. Merge the rollback pull request.
5. Verify the new publication commit.

Do not force push the Wiki or revert only its bot commit. Either action creates
drift that the next successful synchronization will overwrite.

## Reinitialize an empty Wiki

If the Wiki has no `master` ref:

1. Enable **Wikis** under repository settings.
2. Create a minimal `Home` page in the Wiki UI to initialize its Git
   repository.
3. Verify `refs/heads/master` with `git ls-remote`.
4. Dispatch `sync-wiki.yml` from `main`.
5. Verify the bot commit, source SHA, page navigation, and clean local mirror.

Do not seed the Wiki with credentials, deployment outputs, Terraform state,
logs, or other sensitive content.
