# Wiki synchronization

The Markdown files under `wiki/` are the canonical source for the LegendForge
GitHub Wiki. Every regular `*.md` file in that directory is an approved,
publishable page. Contributor and operational documentation belongs under
`docs/`, not in the publishable source directory.

The `Sync Wiki` workflow validates and publishes the source after a reviewed
change reaches `main`. Maintainers can run the exact same mirror locally:

```console
python scripts/sync_wiki_docs.py \
  --source wiki \
  --destination /path/to/LegendForge-CloudCampaigns.wiki
```

## Page map

| Canonical source | Published page |
| --- | --- |
| `wiki/Home.md` | `Home.md` |
| `wiki/_Sidebar.md` | `_Sidebar.md` |
| `wiki/Quickstart.md` | `Quickstart.md` |
| `wiki/Installation.md` | `Installation.md` |
| `wiki/Provider-Guide.md` | `Provider-Guide.md` |
| `wiki/How-To.md` | `How-To.md` |
| `wiki/Prompts.md` | `Prompts.md` |
| `wiki/Use-Cases.md` | `Use-Cases.md` |
| `wiki/Architecture-and-Security.md` | `Architecture-and-Security.md` |

## Managed scope

The synchronizer mirrors every regular `*.md` source file to the top level of
the Wiki checkout using its basename. Validation rejects symlinks, missing
`Home.md`, broken sidebar targets, duplicate basenames, and case-insensitive
filename collisions before the destination changes.

All top-level `*.md` files in the Wiki checkout are managed. A managed page is
removed when no canonical source page has the same name. The Wiki Git metadata,
nested directories, and non-Markdown paths remain untouched.

Links between Wiki pages use repository-friendly targets such as
`[Quickstart](Quickstart.md)` in canonical source. The synchronizer removes the
`.md` suffix in the mirrored content so GitHub routes the link through the Wiki
UI. External links, images, anchors, and code examples are unchanged.

Repository documents linked by a Wiki page use canonical `blob/main` URLs
because the published Wiki has a separate repository root.

The synchronizer writes only pages whose bytes differ. Repeating it with
unchanged source leaves the Wiki checkout with an empty Git diff.

Use `--check` to detect drift without changing the Wiki checkout:

```console
python scripts/sync_wiki_docs.py \
  --source wiki \
  --destination /path/to/LegendForge-CloudCampaigns.wiki \
  --check
```

Check mode exits zero when the checkout is synchronized and one when it would
copy or remove pages. Source or destination validation failures also exit one
and print a diagnostic prefixed with `wiki-sync:`.

## Bot commit and push

The workflow passes the mirrored checkout to `commit_wiki_changes.py`. That
script stages the Wiki worktree, exits successfully without a commit on an
empty diff, and otherwise commits additions, modifications, and deletions as
`github-actions[bot]`. The commit subject records the source repository SHA as
`docs: synchronize from <source-sha>`.

The job-scoped token is available only to the authenticated clone and push
steps. It is not stored in either checkout or passed to the local validation,
mirror, or commit scripts. Pushes are serialized and never forced.

See [Wiki synchronization operations](WIKI_OPERATIONS.md) for publication,
verification, recovery, and rollback procedures.
