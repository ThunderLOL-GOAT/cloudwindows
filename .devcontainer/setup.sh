#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends xfce4 xfce4-terminal dbus-x11 xrdp xorgxrdp mesa-utils libgl1-mesa-dri libglx-mesa0 mesa-vulkan-drivers openjdk-21-jre-headless openjdk-21-jdk curl ca-certificates wget jq unzip xz-utils procps iproute2 net-tools lsof supervisor openssl
install -d -o vscode -g vscode /home/vscode
printf '%s\n' 'exec startxfce4' > /home/vscode/.xsession
chown vscode:vscode /home/vscode/.xsession
chmod 644 /home/vscode/.xsession
adduser xrdp ssl-cert || true
curl -fsSL https://tailscale.com/install.sh | sh

cat >/usr/local/bin/install-modrinth-app <<'INSTALLER'
#!/usr/bin/env bash
set -euo pipefail
asset_url="$(curl -fsSL https://api.github.com/repos/modrinth/theseus/releases/latest | jq -r '.assets[] | select(.name | test("AppImage$"; "i")) | .browser_download_url' | head -n1)"
if [[ -z "$asset_url" || "$asset_url" == "null" ]]; then
  echo "No Linux AppImage was published in the latest official Modrinth release." >&2
  exit 1
fi
install -d -o vscode -g vscode /home/vscode/Applications
curl -fL "$asset_url" -o /home/vscode/Applications/Modrinth.AppImage
chmod 0755 /home/vscode/Applications/Modrinth.AppImage
chown vscode:vscode /home/vscode/Applications/Modrinth.AppImage
INSTALLER
chmod 0755 /usr/local/bin/install-modrinth-app
if ! runuser -u vscode -- /usr/local/bin/install-modrinth-app; then
  echo "Modrinth AppImage unavailable; installer remains at /usr/local/bin/install-modrinth-app."
fi

cat >/usr/local/bin/thunder-start-desktop <<'STARTUP'
#!/usr/bin/env bash
set -euo pipefail
if ! pgrep -x tailscaled >/dev/null 2>&1; then
  mkdir -p /var/run/tailscale
  tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock >/var/log/tailscaled.log 2>&1 &
  for _ in $(seq 1 20); do [[ -S /var/run/tailscale/tailscaled.sock ]] && break; sleep 1; done
fi
if [[ -n "${TAILSCALE_AUTHKEY:-}" ]]; then
  tailscale --socket=/var/run/tailscale/tailscaled.sock up --authkey="${TAILSCALE_AUTHKEY}" --hostname=thunder-linux-codespace --accept-dns=false
  tailscale --socket=/var/run/tailscale/tailscaled.sock ip -4 || true
else
  echo "Tailscale installed but unauthenticated; set TAILSCALE_AUTHKEY as a Codespaces secret for direct private RDP."
fi
if [[ -n "${XRDP_PASSWORD:-}" ]]; then
  printf 'vscode:%s\n' "$XRDP_PASSWORD" | chpasswd
elif [[ ! -s /home/vscode/.xrdp-password ]]; then
  password="$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 20)"
  printf 'vscode:%s\n' "$password" | chpasswd
  install -o vscode -g vscode -m 0600 /dev/null /home/vscode/.xrdp-password
  printf '%s\n' "$password" >/home/vscode/.xrdp-password
  chown vscode:vscode /home/vscode/.xrdp-password
  echo "Generated XRDP password saved at /home/vscode/.xrdp-password."
fi
mkdir -p /var/run/dbus
dbus-daemon --system --fork || true
service xrdp-sesman start || true
service xrdp start || true
sleep 1
if ! pgrep -x xrdp >/dev/null 2>&1; then /usr/sbin/xrdp --nodaemon >/var/log/xrdp.log 2>&1 & fi
echo "XRDP startup requested on TCP 3389."
STARTUP
chmod 0755 /usr/local/bin/thunder-start-desktop
echo "Installed XFCE, XRDP, Mesa, Java 21, Tailscale and Modrinth App installer."
