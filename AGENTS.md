# Agent Guide for meta-foundries

This file guides automation agents to run builds / checks the same way CI does:

- use **kas-container** (isolated from host),
- keep `DL_DIR` and `SSTATE_DIR` outside the repo so caches are shared,
- run `yocto-patchreview` routinely, and run `yocto-check-layer` before
  opening/updating a PR, via the CI helper scripts.

> **Source of truth:** the code in this layer is authoritative. This guide and
> anything under `docs/` are complementary — when they disagree with the
> recipes, classes, and `conf/` in the tree, the code wins. Verify behavior
> against the sources rather than assuming the docs are current.

## Project Overview

meta-foundries is an OpenEmbedded / Yocto Project layer: a collection of recipes
that make up the Foundries.io update solution. It is a software layer (it depends
on `core` and ships no machines of its own); the reference build targets the
`qemuarm64` and `qemuarm64-secureboot` machines provided by OpenEmbedded-Core and
meta-arm.

## 1) Prerequisites

1. `kas-container` available on PATH, or set `KAS_CONTAINER=/abs/path/to/kas-container`
   (from [kas-container](https://github.com/siemens/kas/blob/master/kas-container)).
2. Container runtime access (Docker/Podman backend used by `kas-container`).
3. Work directories outside the repository for build outputs and shared caches.

### Container runtime smoke test (required order)

Run Docker first:

```sh
docker run --rm hello-world
```

Then check Podman:

```sh
if command -v podman >/dev/null 2>&1; then
  podman run --rm hello-world
else
  echo "podman not installed; continue with Docker backend"
fi
```

Notes:

- Do not use `sudo` unless the host setup explicitly requires it.
- Do not create or modify user groups as part of this workflow.
- If Podman is unavailable, Docker-only operation is acceptable.

## 2) Recommended environment

If `KAS_WORK_DIR`, `DL_DIR`, and `SSTATE_DIR` are already set in the environment, use them
directly — do not override them. Only set defaults when they are absent:

```sh
export REPO_DIR="$(pwd)"                                      # meta-foundries checkout
export KAS_WORK_DIR="${KAS_WORK_DIR:-/path/to/kas-work}"      # outside repo to avoid polling the checkout
export DL_DIR="${DL_DIR:-/path/to/shared-cache/downloads}"
export SSTATE_DIR="${SSTATE_DIR:-/path/to/shared-cache/sstate-cache}"
mkdir -p "${DL_DIR}" "${SSTATE_DIR}" "${KAS_WORK_DIR}"
```

## 3) Build with kas-container (CI style)

CI build composition pattern:
`ci/<machine>.yml`

Each machine file includes `ci/include/base.yml`, so a single argument is enough.

Example:

```sh
export KAS_YAMLS="ci/qemuarm64-secureboot.yml"
"${KAS_CONTAINER:-kas-container}" build "${KAS_YAMLS}"
```

The `qemuarm64-secureboot` machine additionally pulls in the `meta-arm` layer
(declared in `ci/qemuarm64-secureboot.yml`):

```sh
"${KAS_CONTAINER:-kas-container}" build ci/qemuarm64-secureboot.yml
```

### Pinned layer revisions

The upstream layers track floating branches, so a build would otherwise follow
whatever landed upstream that morning. The revisions CI builds are pinned in
kas lockfiles:

| lockfile | pins |
| --- | --- |
| `ci/include/base.lock.yml` | `bitbake`, `openembedded-core`, `meta-openembedded`, `meta-updater`, `meta-virtualization` |
| `ci/qemuarm64-secureboot.lock.yml` | `meta-arm` |
| `ci/uno-q.lock.yml` | the Qualcomm layers and `meta-qcom-arduino` |

kas applies these on its own: it looks for `<file>.lock.yml` next to every
config file it loads, includes among them, which is why the base lockfile also
covers `yocto-check-layer` — that check composes `ci/include/base.yml`.
`meta-foundries` itself carries no `url`, so kas never pins it and a build
always uses the working tree: the pull request branch on CI, your checkout
locally.

A change that adds a repo has to add its pin:

```sh
"${KAS_CONTAINER:-kas-container}" lock ci/<machine>.yml
```

Without `--update` this writes only the pins that are missing, so it is safe to
run at any time. The `kas-setup` job runs the same command and fails a pull
request whose lockfiles it changes.

CI pins kas the same way, through `KAS_CONTAINER_IMAGE`, and takes the
`kas-container` script out of that image so the tool and the image cannot
drift apart. A job annotation asks for the pin to move when a newer kas is
released.

Keeping the pins current is the `kas lock update` workflow's job: every
Saturday it runs `kas lock --update`, which ignores the lockfiles and resolves
each layer to the tip of its branch, builds the three machines and
`yocto-check-layer` at those revisions, and opens a pull request only when
they all pass. A red run leaves the pins alone and files an issue, so upstream
breakage never reaches a contributor's pull request.

## 4) Run routine checks via CI helper scripts

For routine local validation, run:

```sh
ci/scripts/kas-container-shell-helper.sh ci/scripts/yocto-patchreview.sh
```

Run `yocto-check-layer` only before opening/updating a pull request:

```sh
ci/scripts/kas-container-shell-helper.sh ci/scripts/yocto-check-layer.sh
```

## 5) Direct kas shell alternative (no helper wrapper)

For one-off commands:

```sh
kas-container shell --skip repos_checkout ci/qemuarm64-secureboot.yml -c "bitbake <target>"
```

Use the helper scripts for CI parity whenever possible.

## 6) Pull request / contribution workflow

Follow the contribution workflow documented in
[CONTRIBUTING.md](CONTRIBUTING.md):

1. Target branch: **main**.
2. Fork `foundriesio/meta-foundries`, clone, and create a topic branch off `main`.
3. Commit with a DCO sign-off (`git commit -s`).
4. Rebase on latest upstream `main` (`git pull --rebase upstream main`).
5. Push to your fork and open a GitHub pull request against `main`.
6. Use PR discussion for review iteration.

Before opening/updating a PR, run CI-equivalent checks:

```sh
ci/scripts/kas-container-shell-helper.sh ci/scripts/yocto-patchreview.sh
ci/scripts/kas-container-shell-helper.sh ci/scripts/yocto-check-layer.sh
ci/scripts/commit-msg-check.sh
```

`ci/scripts/commit-msg-check.sh` runs on the host (git only) and mirrors the CI
Commit Message Check rules: a non-empty subject and body, blank lines
separating the subject, body, and trailers, and 72-character subject and
body lines.

When the change touches `docs/`, also lint the prose with Vale (a PR check in
CI). Both the `ci/` check scripts and the Vale workflow are described in
[docs/ci-scripts.md](docs/ci-scripts.md).

## 7) Commit message best practices (project style)

Follow the requirements in [CONTRIBUTING.md](CONTRIBUTING.md): keep each change
focused and atomic, write a `component: summary of the change` subject (where
`component` names the recipe, directory, or file being touched) and a
plain-English body that explains the problem before the imperative actions, and
include the mandatory `Signed-off-by` (DCO) trailer (and, when an AI assistant
helped produce the change, an `Assisted-by` trailer).

Keep the subject and every body line to 72 characters or fewer, with a blank
line between the subject and the body. CI's Commit Message Check enforces this
and fails the PR on any over-length line, so run `ci/scripts/commit-msg-check.sh`
locally before pushing (see the pre-PR checks above).

When committing programmatically, take the `Signed-off-by` identity from the
local git configuration and append the trailer explicitly:

```text
Signed-off-by: $(git config user.name) <$(git config user.email)>
```

Never fabricate a name or email; always read them from `git config`.

When an AI coding assistant or other advanced tool helped create the change,
acknowledge it with an `Assisted-by` trailer of the form:

```text
Assisted-by: AGENT_NAME:MODEL_VERSION [TOOL1] [TOOL2]
```

`AGENT_NAME` is the AI tool or framework, `MODEL_VERSION` is the specific model
version used, and `[TOOL1] [TOOL2]` are optional specialized analysis tools.
Basic development tools (git, gcc, make, editors) should not be listed. For
example:

```text
Assisted-by: ExampleAgent:example-model-1.0
```

Order the trailers with `Signed-off-by` last, following the Yocto Project
convention. Two reasons.

The sign-off is the human's attestation and it covers the lines above it,
`Assisted-by` included, so last position has the person signing off on the
assisted work. Plenty of contributors automate the trailer and nothing here
can tell who typed it; an agent that appends one is filling in a line the
human stays answerable for.

CI's Commit Message Check knows six trailer names — `Signed-off-by`,
`Co-authored-by`, `Co-developed-by`, `Reviewed-by`, `Acked-by`, and
`Tested-by` — and reads every other line, `Assisted-by` included, as body
text. An `Assisted-by` directly above the sign-off fails the check with
"Body and trailers must be separated by a blank line", so keep a blank line
between them:

```text
Assisted-by: ExampleAgent:example-model-1.0

Signed-off-by: Some One <some.one@example.com>
```

Fixups within a patch series are not allowed. Correct a change in the commit
that introduced it, so every commit in the series stands on its own and the
history stays bisectable.

## 8) Code comments

Comments explain **intent — the "why"** behind the code. They never narrate what the
code does; that is recoverable by reading the code.

- **Minimal.** Use the fewest words that convey the intent. Prefer a single line.
  Delete comments that only echo the code.
- **No contrastive phrasing.** State what *is*, positively. Avoid "not X",
  "instead of", "rather than", "would otherwise", "before the fix", "as opposed to".
- **Capture only non-obvious context** — load-bearing intent, invariants, and
  constraints an agent could not reconstruct from the code itself.
- **Go doc comments** begin with the identifier name and are complete sentences
  (`// distribute stages …`, not `// stages …`).
- Stay technically accurate; invent no behavior.

These rules exist because generated comments tend toward verbose, code-narrating,
contrastive prose that reads as machine-written and ages badly. Write comments a
human would write on purpose.
