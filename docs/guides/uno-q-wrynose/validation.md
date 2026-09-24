# Sources and Validation

Reviewed on 2026-09-23.
This record describes the guide's evidence and limitations, rather than product acceptance or release readiness.

## Source Baseline

| Source | Revision or version | Used for |
| --- | --- | --- |
| [meta-foundries](https://github.com/foundriesio/meta-foundries/tree/4dbe7efc08aef350f247aca83e518a9197c9a31a) | `4dbe7efc08aef350f247aca83e518a9197c9a31a` | UNO Q CI entrypoint, package groups, Android Debug Bridge (ADB) configuration, client recipes |
| [meta-qcom-distro](https://github.com/qualcomm-linux/meta-qcom-distro/tree/c3e4c471ddf7874b95a9d417a61019af25aa2c5b) | Wrynose, `c3e4c471ddf7874b95a9d417a61019af25aa2c5b` | Qualcomm® Linux® (QLI) 2.1 configuration, `qcom-distro-sota`, Wrynose dependency branches |
| [meta-qcom](https://github.com/qualcomm-linux/meta-qcom/tree/18fe56873dc425b0bb6c3a7e7b01af0c14005288) | Wrynose, `18fe56873dc425b0bb6c3a7e7b01af0c14005288` | BitBake 2.18, firmware mixin, ADB image class |
| [`meta-qcom-arduino`](https://github.com/qualcomm-linux/meta-qcom-arduino/tree/35f3dfdd4dca56d0df60b621ff8fd70a8043bcfd) | `35f3dfdd4dca56d0df60b621ff8fd70a8043bcfd` | UNO Q machine and Wrynose compatibility declaration |
| [meta-updater](https://github.com/uptane/meta-updater/tree/92f4788c30fdcab2d376eb9ae6b191bda7d06d0a) | Wrynose, `92f4788c30fdcab2d376eb9ae6b191bda7d06d0a` | OTA integration layer |
| [Foundries Update Server](https://github.com/foundriesio/update-server/tree/208e846d50febb6024953ff5a0079b45b900a58b) | `208e846d50febb6024953ff5a0079b45b900a58b` | Bootstrap, enrollment, CLI, configuration selection, upload and rollout implementation |
| [composeapp](https://github.com/foundriesio/composeapp/tree/0af6d7702713f36848ae569dc7a6c7f05f1d2abe) | `0af6d7702713f36848ae569dc7a6c7f05f1d2abe` | `composectl`, matched to meta-foundries' recipe |
| [aktualizr-lite](https://github.com/foundriesio/aktualizr-lite/tree/7bb558258bd64214abf27e4bb6567a17f9cf7854) | `7bb558258bd64214abf27e4bb6567a17f9cf7854` | App reference comparison and unchanged OS handling, matched to meta-foundries' recipe |
| [Foundries containers](https://github.com/foundriesio/containers/tree/5be067eb56d1cb59dcbf82568f36986705af9a8a/shellhttpd) | `5be067eb56d1cb59dcbf82568f36986705af9a8a` | Existing shellhttpd Dockerfile, script, and Compose example |
| [Arduino documentation](https://github.com/arduino/docs-content/tree/dab66ecbd6ad52cd742da6c19c5b6330a7f2caae) | `dab66ecbd6ad52cd742da6c19c5b6330a7f2caae` | Bughopper connection, 115200 baud, Emergency Download (EDL) procedure, linked hardware illustrations |
| [kas](https://github.com/siemens/kas/tree/5.4) | 5.4 | Wrapper, schema, lock command, container version variable |
| [`qdl`](https://github.com/linux-msm/qdl/tree/v2.8) | 2.8 | Host binaries, flashing syntax, Windows Subsystem for Linux (WSL) USB limitation |

## Relationship to the Upstream Server Documentation

The guide follows these documents, checked at the pinned server revision:

- [`quick-start.md`](https://github.com/foundriesio/update-server/blob/208e846d50febb6024953ff5a0079b45b900a58b/docs/quick-start.md): development bootstrap and device registration.
- [`build-an-update.md`](https://github.com/foundriesio/update-server/blob/208e846d50febb6024953ff5a0079b45b900a58b/docs/build-an-update.md): image publication, Compose app publication, and offline content download.
- [`updates.md`](https://github.com/foundriesio/update-server/blob/208e846d50febb6024953ff5a0079b45b900a58b/docs/updates.md): upload, target versioning, and rollout.
- [`fiocli.md`](https://github.com/foundriesio/update-server/blob/208e846d50febb6024953ff5a0079b45b900a58b/docs/fiocli.md): CLI authentication and contexts.

The upstream QLI/meta-foundries build subsection is unfinished at this revision.
This guide adds the Wrynose configuration and the container wrapper around the documented development-server bootstrap.
It does not use `contrib/run-local.sh`: that script populates mock data for UI development and does not enroll real hardware.

The current CLI takes an update name, such as `unoq-001`, for rollout commands.
The guide follows that implementation rather than copying older `/ci/<tag>/...` API examples.
The guide downloads and uploads app blobs; supplying only `--apps name=digest` would not supply the required content.

## Design Choices

- QLI, Qualcomm BSP, and core dependency layers use Wrynose; BitBake uses 2.18.
- meta-foundries has no Wrynose branch at the review date. Its pinned revision declares Wrynose compatibility.
- The Arduino layer has only `main` at the review date. Its pinned revision declares Wrynose compatibility.
- A kas lockfile captures the remaining floating Wrynose references before the first build.
- The OS build runs on x86-64 Linux. macOS and Windows ARM readers use a separate Linux builder.
- The server and tools are built from the same pinned source inside Docker.
- Both containers run as a non-root user whose IDs match the local packaging account.
  New named volumes use that user's ownership; the CLI configuration resides under `/home/guide/.config`.
- The server's local-network hostname is set explicitly when creating its public key infrastructure (PKI).
  Container-generated hostnames are unsuitable for the board.
- GitHub Container Registry (GHCR) setup is an optional separate page. Private packages work because authenticated packaging downloads the complete app content.
- The example keeps the existing Foundries shellhttpd implementation and changes its Compose `MSG` between releases.
- The second release changes both the OS `BUILD_ID` and the app message, making both changes observable.
- The third release adds an independent `statushttpd` Compose app, reusing the Foundries example on port 8081.
- The fourth release rebuilds the `shellhttpd` image with a visible HTTP header and retains the original `statushttpd` digest.
- Both application-only uploads omit the OS repository and pass the device's current OS checksum explicitly through `--ostree-hash`.
  The server otherwise substitutes the SHA-256 checksum of empty content; omission does not preserve the installed OS automatically.
- Application-only verification checks the original boot ID, OS checksum, and OS build ID, together with both application responses.

## Execution Still Required

The authoring computer has no Docker runtime or connected UNO Q available for this task.
No container launch, QLI compilation, firmware flashing, registration, or rollout is claimed as tested.

Before calling the guide hardware-validated, record the following results with the generated lockfile:

| Check | Required evidence | Status |
| --- | --- | --- |
| Wrynose build | kas lockfile, build result, manifests, flash bundle, OS repository | Not run |
| Bughopper path | Serial settings, boot log, working input | Not run |
| ADB path | Device enumeration, root shell, Wi-Fi setup | Not run |
| Host paths | Linux, macOS Docker Desktop, Windows Docker Desktop/WSL; native USB access | Not run |
| Container setup | Non-root identity, writable workspace and configuration, readable registry credentials, initialization, restart with persisted volume | Not run |
| Enrollment | Successful board command, device identifier, heartbeat over gateway | Not run |
| App selection | fioconfig delivery and requested app list | Not run |
| First rollout | shellhttpd version 1 response and server result | Not run |
| Second rollout | New OS build ID, changed boot ID/deployment, version 2 response, server success | Not run |
| Add a second application | Both HTTP apps respond; original app digest, OS checksum/build ID, and boot ID retained | Not run |
| Update only the existing app | New image's HTTP header and message; second app digest, OS checksum/build ID, and boot ID retained | Not run |

The host resource allowance is a planning estimate, not a measured minimum.
The server Dockerfile and kas override are newly authored companion files, not upstream-supported release artifacts.

## Authoring Checks Completed

- All three kas YAML files pass the kas 5.4 JSON schema.
- An offline expansion of the pinned upstream CI includes confirms the Wrynose branch overrides,
  pinned integration exceptions, `uno-q` machine, `qcom-distro-sota` distro, and image target.
- The Docker Compose file passes the official Compose JSON schema.
- All Bash blocks pass `bash -n`; this verifies shell syntax, not command execution.
- Relative Markdown links and heading anchors resolve within the guide directory.
- All six diagrams pass the Mermaid 11 parser; sequence-note line breaks use `<br/>` rather than unescaped semicolons.
- After relocating the tutorial into this repository, all 53 Bash blocks and 49 local Markdown links pass their checks.
  Every original command and configuration block is preserved exactly once across the split pages.
- The two official hardware images were retrieved and visually checked.
- The bootstrap hostname flag spelling was checked against the server and argument-parser sources.

These checks do not establish layer compatibility beyond the declarations, container startup, or successful device updating.

## Documentation Review Still Required

The tutorial uses title-case headings, defines unfamiliar acronyms, and uses registered trademark symbols at first body mention.
The flagged long sentences and ambiguous instructions have been clarified.
Remaining Vale findings include date punctuation, generic target capitalization, and false positives for defined acronyms and literal identifiers.
The acronym rule does not recognize some definitions containing lowercase words or trademark symbols.
The branding rule also suggests replacing the word "exceptions" with `?:+.py` because its exception configuration is nested under its replacement mapping.
The tutorial retains ISO-8601 dates, lowercase generic targets, and the word "exceptions".
These findings require rule or terminology review; the guide does not apply the malformed replacement.
The advisory Vale CI job can pass while findings remain.

The local environment has no Docker, Podman, or installed kas-container.
The repository's container-based `yocto-patchreview` and `yocto-check-layer` checks could not run.
Run those checks through CI or a configured Linux environment before marking the contribution ready for review.

## Illustrations

The diagrams are original Mermaid source embedded in Markdown.
Hardware images link to Arduino's published documentation at the recorded revision, with attribution and alt text.
They require network access when the Markdown viewer loads them.
No generated hardware image or invented UI screenshot is used.
