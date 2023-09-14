# docs.nefarius.at

[![ci](https://github.com/nefarius/docs.nefarius.at/actions/workflows/ci.yml/badge.svg)](https://github.com/nefarius/docs.nefarius.at/actions/workflows/ci.yml) [![Website](https://img.shields.io/website-up-down-green-red/https/docs.nefarius.at.svg?label=docs.nefarius.at)](https://docs.nefarius.at/)

Sources of [docs.nefarius.at](https://docs.nefarius.at/).

## Build local Docker/Podman instance

```bash
podman build -t mkdocs .
podman run -it --rm -v "${PWD}:/docs" -p "8000:8000" localhost/mkdocs:latest
```

The built site will be available at [localhost:8000](http://localhost:8000/).

## Branches

- `master` changes will get built and pushed online ASAP
- `devel` can be used to make changes without affecting the currently online version

## 3rd party credits

- [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/)
- [PyMdown Extensions](https://facelessuser.github.io/pymdown-extensions/extensions/arithmatex/)
- [Python-Markdown](https://python-markdown.github.io/)
- [Emfed](https://github.com/sampsyo/emfed)
- [mkdocs-glightbox](https://github.com/Blueswen/mkdocs-glightbox)
