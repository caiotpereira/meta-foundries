---
title: Set Up the Server and Register UNO Q
description: Run the local update server, register the device, and select its applications.
date: 2026-09-23
status: Source-reviewed draft; hardware walkthrough pending
---

# Set Up the Server and Register UNO Q

[Guide overview](README.md) · [Previous: Build and flash](build-flash.md) · **Part 2 of 3**

Complete [build and flash](build-flash.md) first.
The board must be running OS version 1, connected to your local area network (LAN), and accessible through your chosen console.

Use the local computer that will run Docker, with the complete guide directory and `GUIDE_DIR` set to its absolute path.
Keep this host Bash session open for the application exercises so `GUIDE_DIR`, `UNOQ_UUID`, and the `dc` function remain available.

> **Validation status:** Source-reviewed draft. The complete build and hardware walkthrough remain pending.
> See [sources and validation](validation.md).

- [Start the update server on your computer](#start-the-update-server-on-your-computer)
- [Register the UNO Q](#register-the-uno-q)
- [Select the applications the board should run](#select-the-applications-the-board-should-run)
- [Stop and restart the local server](#stop-and-restart-the-local-server)

## Start the Update Server on Your Computer

Run this section in your **local host shell**: Linux®, macOS Terminal, or Ubuntu in Windows Subsystem for Linux (WSL).
It follows the upstream [development-server bootstrap](https://github.com/foundriesio/update-server/blob/208e846d50febb6024953ff5a0079b45b900a58b/docs/quick-start.md)
inside a container with persistent storage.

This is a local development server.
Its enrollment UI uses HTTP, and the image enables development console access.
Use a trusted lab network and keep these ports off the public Internet.

### Give the Server a Name Reachable From the Board

Use the hostname **`unoq-update.test`** throughout this guide.
Choose the computer's LAN IPv4 address, not a Docker, WSL, VPN, or loopback address.
Reserve that address through your router's Dynamic Host Configuration Protocol (DHCP) settings if possible.

| Host | Find the address |
| --- | --- |
| Linux | `ip -4 address` on the LAN interface |
| macOS | System Settings → Network → connected interface → Details → TCP/IP |
| Windows | `ipconfig` in PowerShell; use the active Wi-Fi/Ethernet adapter's IPv4 address |

In the guide's root directory, enter the address you found above when prompted.
Use the **LAN IPv4 address of the computer running Docker**, not the UNO Q's address.
There is no default address; the value depends on your network.

| Name used in this guide | Address it identifies |
| --- | --- |
| `UPDATE_SERVER_HOST_IP` | The computer running the Foundries Update Server container |
| `UNOQ_DEVICE_IP` | The UNO Q board |

```bash
cd "$GUIDE_DIR"
read -r -p "Enter the update-server computer's LAN IPv4 address: " UPDATE_SERVER_HOST_IP
export UPDATE_SERVER_HOST_IP
printf 'UPDATE_SERVER_HOST_IP=%s\n' "$UPDATE_SERVER_HOST_IP" > .env
printf 'GUIDE_UID=%s\nGUIDE_GID=%s\n' "$(id -u)" "$(id -g)" >> .env
dc() { docker compose --env-file "$GUIDE_DIR/.env" -f "$GUIDE_DIR/server/compose.yml" "$@"; }
```

**Run every `dc ...` command in a terminal on the computer running the update server.**
Use a Linux shell, macOS Terminal, or Ubuntu WSL on Windows, with access to that computer's Docker engine.
Keep this terminal separate from the UNO Q's serial or Android Debug Bridge (ADB) shell.

`dc` is the shell function above, which calls Docker Compose with this guide's configuration.
For example, `dc run --rm tools fiocli devices list` starts a temporary `tools` container and runs `fiocli devices list` inside it.
Docker removes that temporary container when the command finishes; the saved CLI login remains in its named volume.
The update-server container continues running separately.

Use your regular host account for this walkthrough.
The image creates a non-root `guide` user with the numeric user and group IDs recorded in `.env`.
Matching those IDs lets the tools write files in `workspace/` and read your restricted `.registry-auth/` directory.
On Windows, record the IDs from the Ubuntu WSL shell where you keep those directories.
The image build rejects zero IDs.

Keep `GUIDE_DIR` set to the guide directory.
If you open a new terminal, set `GUIDE_DIR` and define the `dc` function there again.
The function uses absolute configuration paths, so `dc` commands work from any directory in that terminal.

Generate the hosts-file entry from the address you entered:

```bash
printf '%s unoq-update.test\n' "$UPDATE_SERVER_HOST_IP"
```

Copy the **printed output** into the computer's hosts file and the UNO Q's `/etc/hosts`.
Use the same entry in both places; do not paste the shell variable name into a hosts file.

On Linux/macOS, edit `/etc/hosts` with administrator privileges.
On Windows, edit `C:\Windows\System32\drivers\etc\hosts` as Administrator;
also add the entry to WSL's `/etc/hosts` if using that shell to access the hostname.
Docker Compose supplies the same mapping to the tools container from `.env`.

On the **UNO Q**, edit the hosts file as root and add the printed entry if it is not already present:

```bash
vi /etc/hosts
```

The host shell's `UPDATE_SERVER_HOST_IP` variable is not automatically available in the board's shell.
After saving the file, check the mapping on the **UNO Q**:

```bash
getent hosts unoq-update.test
```

The result must show the computer's LAN address that you entered earlier.

If the address changes, replace the existing hosts entries and `.env` value.
Keeping the hostname unchanged preserves the certificate name.

Allow inbound Transmission Control Protocol (TCP) connections on ports **8080 and 8443** from the board's LAN through the computer's firewall.
For Docker Desktop, use the computer's LAN address with the published ports.
Do not point the board at the internal Docker container IP or WSL IP.

### Build and Initialize the Container

```bash
cd "$GUIDE_DIR"
dc build server
dc run --rm tools sh -c 'id; test "$(id -u)" -ne 0 && test -w /work && test -w /home/guide/.config'
dc run --rm server fioserver --datadir=/data devserver-init \
  --dnsname=unoq-update.test --factory=unoq-lab
dc up -d server
dc logs --tail=50 server
```

Initialize the named volume **once**.
The bootstrap creates the factory public key infrastructure (PKI) and The Update Framework (TUF) metadata.
It also creates the local `admin` account with development password `admin`.
The explicit DNS name prevents a random container hostname from entering the gateway certificate.
If initialization prints a suggested IP address, use your computer's LAN address instead of the container address.

Open [the local server](http://unoq-update.test:8080/) and sign in as `admin` / `admin`.
The container publishes both the UI/enrollment port and the device gateway port.
Its data, keys, device records, and updates persist in the `unoq-lab_server-data` named volume.
New data and CLI configuration volumes inherit the image's directory ownership for the non-root user.
Reusing volumes from an earlier root-based setup requires an ownership migration before following these commands.

On the **UNO Q**, check connectivity:

```bash
curl -I http://unoq-update.test:8080/
```

A response or redirect confirms HTTP reachability.
Registration and the subsequent device heartbeat will verify the authenticated gateway path.

## Register the UNO Q

On the **UNO Q**, stop the updater before enrollment, then run:

```bash
systemctl stop aktualizr-lite
fio-device-register \
  --device-api=http://unoq-update.test:8080/v1/devices \
  --oauth-api=http://unoq-update.test:8080/oauth2 \
  --factory=unoq-lab \
  --name=unoq-01 \
  --tag=wrynose
```

Open the authorization link printed by the command in your computer's browser.
Sign in to the local update server, enter the displayed code if requested, and approve this device.
Wait for `fio-device-register` to report success on the board.
The factory name must match `devserver-init`; the `wrynose` tag must match the updates you upload later.

Check the services on the **UNO Q**:

```bash
systemctl start aktualizr-lite fioconfig
systemctl --no-pager status aktualizr-lite fioconfig docker
journalctl -u aktualizr-lite -n 50 --no-pager
```

The image's registration tool requests Compose application support.
Confirm `/var/sota/sota.toml` contains `type = "ostree+compose_apps"` in its `[pacman]` section.
Do not print or share the private key from this directory.

In the server UI, open **Devices** and find `unoq-01`.
Confirm a recent device heartbeat, then copy its universally unique identifier (**UUID**).
A completed browser authorization alone is insufficient if the board command failed.

Return to the terminal on the **computer running the update server**.
Use the terminal where you defined `GUIDE_DIR` and `dc`, and log the containerized CLI into the server:

```bash
dc run --rm tools fiocli login unoq-local http://unoq-update.test:8080
```

Complete the browser authorization printed by `fiocli`.
Its login state persists in the separate `cli-config` volume.

```bash
dc run --rm tools fiocli devices list
export UNOQ_UUID='PASTE_THE_DEVICE_UUID'
```

## Select the Applications the Board Should Run

In the same **update-server computer terminal**, select `shellhttpd` for this device and keep its update tag on Wrynose:

```bash
dc run --rm tools fiocli configs updates --device "$UNOQ_UUID" \
  --tag wrynose --apps shellhttpd
```

This records the desired application selection.
The application starts after an update containing `shellhttpd` is uploaded and rolled out.
The first selection uses the CLI because a newly enrolled device may not yet have an app catalog in the UI.

For later changes, use these alternatives:

| Desired result | Value for `--apps` |
| --- | --- |
| Run shellhttpd | `shellhttpd` |
| Run two apps present in the update | `shellhttpd,another-app` |
| Run no apps | `,` |
| Remove this override and use the device's configured defaults | `-` |

For example, `fiocli configs updates --device "$UNOQ_UUID" --apps ','` disables all applications.
Changing the selection does not create application content; selected names must exist in the update.
Allow the configuration client and updater time to poll the server.

## Stop and Restart the Local Server

After finishing your work, use the same **update-server computer terminal** to stop or restart the server:

```bash
dc stop server
dc start server
```

`dc down` removes the containers and network while retaining named volumes.
Avoid `dc down -v` unless you deliberately intend to discard the server's keys, enrollment records, and updates.
Do not rerun `devserver-init` against the initialized volume.

**Next:** [Deploy and update applications](application-updates.md).
Leave the server running and continue in the same host Bash session.
