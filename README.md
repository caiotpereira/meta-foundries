# meta-foundries

A collection of recipes that make up the Foundries.io update solution.

## Getting in Contact

* [Report an Issue on GitHub](../../issues) — for bugs, build failures, and
  feature requests.
* To report a security vulnerability, follow the process in
  [SECURITY.md](SECURITY.md).

## Maintainer(s)

- Daiane Angolini <daiane.angolini@oss.qualcomm.com>
- Mike Scott <mike.scott@oss.qualcomm.com>

## License

- *meta-foundries* is licensed under the [MIT](COPYING.MIT) license.

## Layer Dependencies

This layer depends on:

```text
URI: https://git.openembedded.org/openembedded-core
layers: meta
branch: master
revision: HEAD
```

```text
URI: https://git.openembedded.org/meta-openembedded
layers: meta-oe, meta-python, meta-filesystems, meta-networking
branch: master
revision: HEAD
```

```text
URI: https://github.com/uptane/meta-updater
layers: meta-updater (collection "sota")
branch: master
revision: HEAD
```

meta-oe carries the `libp11` recipe that the device-register build needs.
meta-updater carries the `asn1c` compiler the update client build needs.
meta-python, meta-filesystems and meta-networking are there because
meta-updater and its own dependencies require them.

This layer has an optional dependency on the meta-virtualization layer:

```text
URI: https://git.yoctoproject.org/meta-virtualization
layers: meta-virtualization (collection "virtualization-layer")
branch: master
revision: HEAD
```

It is only required for container support: the Docker engine, Compose
Apps, and the dockerd configuration and patches this layer applies. The
recipes for it live under `dynamic-layers/virtualization-layer/` and are
only parsed when meta-virtualization is in BBLAYERS. They also need
`virtualization` in `DISTRO_FEATURES`, and the dockerd changes need
`sota` there as well. An image with OS updates only does not need the
layer.

This layer has an optional dependency on the meta-arm layer:

```text
URI: https://git.yoctoproject.org/meta-arm
layers: meta-arm, meta-arm-bsp
branch: master
revision: HEAD
```

The dependency is optional, and only required for the `qemuarm64-secureboot`
machine. When that machine is not used (e.g. an Intel target), the layer is not
needed and does not have to be enabled in BBLAYERS.

## Adding the meta-foundries layer to your build

Run 'bitbake-layers add-layer meta-foundries'

## Contributing

Please submit any patches against the `meta-foundries` layer by using the
GitHub pull-request feature. Fork the repo, create a branch, do the work,
rebase from upstream, and create the pull request.

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to contribute, including the
checks to run before submitting a pull request.

## Documentation

Detailed usage, build, and testing instructions live in the [`docs/`](docs/)
directory. [`docs/COMPONENTS.md`](docs/COMPONENTS.md) lists what the layer
ships and where each component comes from.
