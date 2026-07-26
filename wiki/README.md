# LegendForge Wiki Source Pages

This directory contains GitHub wiki-ready Markdown pages built from the current repository documentation.

Use these files as the source set for the repository wiki:

- [Home.md](Home.md)
- [_Sidebar.md](_Sidebar.md)
- [Quickstart.md](Quickstart.md)
- [Installation.md](Installation.md)
- [How-To.md](How-To.md)
- [Provider-Guide.md](Provider-Guide.md)
- [Prompts.md](Prompts.md)
- [Use-Cases.md](Use-Cases.md)
- [Architecture-and-Security.md](Architecture-and-Security.md)

These pages summarize and cross-link the existing LegendForge documentation so they can be published into the GitHub wiki.

Because the GitHub wiki is a separate repository, these files are stored here as the maintained source set for wiki publication.

## Navigation and publication

- Read the rendered pages in the [published GitHub Wiki](https://github.com/sodejm/LegendForge-CloudCampaigns/wiki).
- Use the `.md` links above when reviewing source files in this repository.
- Publish source changes to the repository's separate wiki before treating the rendered wiki as current. A merge to this repository does not update the published wiki by itself.

Links between publishable wiki pages use canonical
`https://github.com/sodejm/LegendForge-CloudCampaigns/wiki/<Page>` URLs. Those
links work from both this source directory and the rendered wiki. Repository
documents linked from wiki pages use canonical `blob/main` URLs because the
published wiki has a separate repository root.

Do not use extensionless relative targets such as `Quickstart` in these source
files. GitHub Wiki resolves that form after publication, but it is broken when
the Markdown source is browsed in this repository.
