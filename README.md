# docs.nefarius.at

[![CI](https://github.com/nefarius/docs.nefarius.at/actions/workflows/ci.yml/badge.svg)](https://github.com/nefarius/docs.nefarius.at/actions/workflows/ci.yml)
[![Website](https://img.shields.io/website-up-down-green-red/https/docs.nefarius.at.svg?label=docs.nefarius.at)](https://docs.nefarius.at/)
[![Assisted by Cursor AI](https://img.shields.io/badge/Assisted%20by-Cursor%20AI-8B5CF6?style=flat)](https://cursor.com/)

Source repository for **[docs.nefarius.at](https://docs.nefarius.at)** — the documentation site for Nefarius projects (USB input device emulation, game peripherals, reverse engineering, and related tooling).

---

## Local build

Requires [Docker](https://www.docker.com/). From the repo root:

```bash
docker build -t mkdocs .
docker run -it --rm -v "${PWD}:/docs" -p "8000:8000" mkdocs:latest
```

The site is served at **http://localhost:8000**.

---

## Branch policy

| Branch   | Purpose |
|----------|--------|
| `master` | Production. Changes are built and deployed to the live site. |
| `devel`  | Staging. Use for edits that should not go live yet. |

---

## Contributing

Found a typo, unclear step, or missing info? [Open a pull request](https://github.com/nefarius/docs.nefarius.at/compare). New to GitHub PRs? [first-contributions](https://github.com/firstcontributions/first-contributions) has a short guide.

---

## Built with

- [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/)
- [PyMdown Extensions](https://facelessuser.github.io/pymdown-extensions/)
- [Python-Markdown](https://python-markdown.github.io/)
- [Emfed](https://github.com/sampsyo/emfed)
- [mkdocs-glightbox](https://github.com/Blueswen/mkdocs-glightbox)
- [mkdocs-redirects](https://github.com/mkdocs/mkdocs-redirects)
