# LegendForge Wiki Source Pages

This directory contains GitHub wiki-ready Markdown pages built from the current repository documentation.

Use these files as the source set for the repository wiki:

- `Home.md`
- `_Sidebar.md`
- `Quickstart.md`
- `Installation.md`
- `How-To.md`
- `Provider-Guide.md`
- `Prompts.md`
- `Use-Cases.md`
- `Architecture-and-Security.md`

These pages summarize and cross-link the existing LegendForge documentation so they can be published into the GitHub wiki.

Because the GitHub wiki is a separate repository, these files are stored here as the maintained source set for wiki publication.

## Link format note

Internal links between wiki pages use extensionless wiki-style links (for example `[Quickstart](Quickstart)`).
These links work correctly when the files are published to the GitHub wiki, where page names are resolved without extensions.
When browsing the `wiki/` source files directly in this repository the links will not resolve, because the files are named `Quickstart.md`, `Installation.md`, etc.
To navigate between pages from within the repository, use the `.md` suffixed filenames directly.
