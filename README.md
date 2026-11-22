# Thunder Cloud Linux Desktop

This branch configures a Linux desktop inside GitHub Codespaces.

## Build the environment

1. Open this repository on the `linux` branch.
2. Create a Codespace from that branch, or use **Codespaces: Rebuild Container** for an existing Codespace.
3. Wait for post-create setup. It installs XFCE, XRDP, Mesa userspace libraries, Java 21, Tailscale, and attempts to install the latest official Modrinth App Linux AppImage.

## ThunderRemote connection

Port `3389` is forwarded as private. GitHub's forwarded-port URL is an HTTPS web proxy, not a raw RDP endpoint, so do not enter that URL into an RDP client.

For direct ThunderRemote access, add a Tailscale auth key as a **Codespaces secret** named `TAILSCALE_AUTHKEY`, then restart the Codespace. The daemon uses Tailscale userspace networking (so it does not require `/dev/net/tun`) and publishes a private raw-TCP Serve forwarder from tailnet port `3389` to the local XRDP service. It joins your tailnet as `thunder-linux-codespace`. Connect ThunderRemote to the machine's Tailscale IPv4 address on port `3389`.

Keep port 3389 private and never paste the Tailscale key into chat. The RDP username is `vscode`. If you do not set an `XRDP_PASSWORD` Codespaces secret, a random password is saved in `/home/vscode/.xrdp-password`; read it in the Codespace terminal with:

```bash
cat ~/.xrdp-password
```

## Modrinth App

From the XFCE desktop, run:

```bash
~/Applications/Modrinth.AppImage
```

If the latest release has no AppImage, retry the official-release lookup with:

```bash
sudo install-modrinth-app
```

## Performance limits

Codespaces is a development container, not a dedicated GPU cloud PC. Mesa supplies OpenGL libraries and a software-rendering fallback, but does not grant GPU passthrough or guarantee hardware acceleration. Check the actual renderer with `glxinfo -B` and Java with `java -version`.

Codespaces can stop when idle and has usage/runtime limits. Minecraft FPS and remote input latency depend on the host and renderer; benchmark the same scene before relying on it for PvP.
