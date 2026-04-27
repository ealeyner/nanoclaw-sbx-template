# nanoclaw-sbx-template

Docker Sandboxes template that pre-bakes NanoClaw's prerequisites (Node, pnpm, build tools) for one-command sandbox startup.

Running NanoClaw inside a Docker Sandbox normally requires ~30 minutes of manual setup: installing Node, pnpm, build tools, warming the pnpm store, and applying six patches to make Docker-in-Docker work. This repo collapses that into a single template build — you run `build-template.sh` once, snapshot the result, and anyone on the team can start in under a minute with `nanoclaw-init`.

> **Note**: The NanoClaw clone itself is intentionally **not** baked into the template — DinD inside a Docker Sandbox can only bind-mount paths under the workspace directory passed to `sbx create`, so the repo must live under `$WORKSPACE` at runtime, not in the image.

## Prerequisites

- Docker Desktop ≥ 4.40
- `docker-sbx` ≥ 0.27
- `sbx login` completed

## Build it yourself

```bash
./build-template.sh nanoclaw:v1
```

Produces `out/nanoclaw_v1.tar` and registers the template locally.

## Use a prebuilt tarball

```bash
# Import the tarball
sbx template load nanoclaw_v1.tar

# Start a sandbox from the template
sbx run -t nanoclaw:v1 shell ~/proj

# Inside the sandbox: clone NanoClaw and install deps
nanoclaw-init
```

`nanoclaw-init` clones the [`sandbox-ready` branch](https://github.com/ealeyner/nanoclaw/tree/sandbox-ready) of the NanoClaw fork (which has the six DinD patches pre-applied) into `$WORKSPACE/nanoclaw`, runs `pnpm install --prefer-offline` against the warmed store, and prints next steps.

If the `sandbox-ready` branch isn't available, the script falls back to upstream [`qwibitai/nanoclaw` main](https://github.com/qwibitai/nanoclaw) automatically.

## Environment variables for `nanoclaw-init`

| Variable | Default | Description |
|---|---|---|
| `NANOCLAW_BRANCH` | `sandbox-ready` | Branch to clone |
| `NANOCLAW_REPO` | `https://github.com/ealeyner/nanoclaw.git` | Repo to clone from |

Override to pin a version or use your own fork:

```bash
NANOCLAW_BRANCH=main nanoclaw-init ~/proj
```

## CI / GitHub Actions

The included `docs/release.yml.example` workflow fires on tag push and attempts to build and upload the template tarball as a release asset. **`sbx login` requires Docker credentials that aren't available in GitHub-hosted runners**, so the build step is skipped in CI — local builds are the supported path. The workflow is best-effort and included as a future enhancement.

To activate it, copy it to `.github/workflows/release.yml` in your own fork (requires a GitHub token with `workflow` scope):

```bash
mkdir -p .github/workflows
cp docs/release.yml.example .github/workflows/release.yml
git add .github/workflows/release.yml
git commit -m "Enable CI workflow"
git push
```

## Further reading

- [`docs/docker-sandboxes.md`](https://github.com/qwibitai/nanoclaw/blob/main/docs/docker-sandboxes.md) — manual setup guide (the six patches this template automates)
- [Track A PR](https://github.com/qwibitai/nanoclaw/pulls) — pre-applied patches on the `sandbox-ready` branch

## License

MIT © ealeyner 2026
