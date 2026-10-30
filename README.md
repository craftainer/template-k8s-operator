# template-docker

> [!NOTE]
> This repository is vibe coded with [Claude](https://claude.com/product/claude-code).

The shared image layer for container-shipping apps: an instance of
[`template-base`](https://github.com/craftainer/template-base) that is
itself a template. On top of base's devcontainer, CI and AI-assisted
workflow it adds the image release `Makefile` (multi-arch OCI build, SBOM,
labels, registry publish, smoke test), a skeleton runtime `Dockerfile`
with an arbitrary-UID `runner` stage, and Dockerfile lint, version-check
and image-scan hooks. App templates such as `template-fastapi` instantiate
this one and sync from it. See [`docs/TEMPLATE.md`](docs/TEMPLATE.md) for
the details and [`docs/adrs/0001-shared-image-layer-as-template-docker-mid-layer.md`](docs/adrs/0001-shared-image-layer-as-template-docker-mid-layer.md)
for why.

Once instantiated, rename this file's title and description to the
actual project's; `docs/TEMPLATE.md` stays as-is and is what
`.github/workflows/template-sync.yml` keeps up to date.

## License

Licensed under the [GNU General Public License v3.0](LICENSE).
