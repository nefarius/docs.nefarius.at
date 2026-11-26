# docs.nefarius.at

[![CI](https://github.com/nefarius/docs.nefarius.at/actions/workflows/ci.yml/badge.svg)](https://github.com/nefarius/docs.nefarius.at/actions/workflows/ci.yml)
[![Website](https://img.shields.io/website-up-down-green-red/https/docs.nefarius.at.svg?label=docs.nefarius.at)](https://docs.nefarius.at/)
[![Assisted by Cursor AI](https://img.shields.io/badge/Assisted%20by-Cursor%20AI-8B5CF6?style=flat)](https://cursor.com/)

Source repository for **[docs.nefarius.at](https://docs.nefarius.at)** — the documentation site for Nefarius projects (USB input device emulation, game peripherals, reverse engineering, and related tooling).

---

## Local build

The site is built with [Zensical](https://zensical.org/) (pinned in [`requirements.txt`](requirements.txt) and [`compose.yaml`](compose.yaml)) using [`zensical.toml`](zensical.toml).

Start a live-reloading preview from the repo root with [Docker](https://www.docker.com/):

```bash
docker compose up
```

The site is served at **http://localhost:8000**. Set `ZENSICAL_PORT` before `docker compose up` when port 8000 is already in use.

Stop the preview and remove its isolated build volumes:

```bash
docker compose down --volumes
```

Run a clean strict build check (matching CI without leaving the preview server running):

```bash
docker compose down --volumes
docker compose run --rm zensical build --strict
```

Because `compose.yaml` mounts `/docs/.cache` as a named volume, `zensical build --clean` cannot remove that directory directly; resetting the volumes with `docker compose down --volumes` runs the same clean build without writing root-owned cache files into the workspace.

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

- [Zensical](https://zensical.org/)
- [PyMdown Extensions](https://facelessuser.github.io/pymdown-extensions/)
- [Python-Markdown](https://python-markdown.github.io/)
- [Emfed](https://github.com/sampsyo/emfed)
