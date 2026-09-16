# docker-chrony

Rootless Chrony (NTP) Docker image built around one requirement: full, direct control over `chrony.conf` — nothing generated, nothing overwritten.

## Why

We run Chrony as the NTP source for Cisco devices using **Secure NTP** (per-server SHA1/MD5 authentication keys). That means `chrony.conf` needs an explicit `keyfile` directive and `key N` options per server, and those settings must persist exactly as configured — never regenerated on container restart. This image is built so that whatever `chrony.conf` you mount is exactly what `chronyd` runs with.

## Repository structure

```
image/
  Dockerfile
  chrony.conf       # default fallback config, baked into the image
.github/workflows/
  build.yml
digest.txt          # tracks the last-published image content hash
README.md
CHANGELOG.md
```

## Usage

```yaml
services:
  chrony:
    image: ghcr.io/clbsoldev/chrony-ntp-server:latest
    restart: unless-stopped
    ports:
      - "123:123/udp"
    volumes:
      - ./chrony.conf:/etc/chrony/chrony.conf:ro
      - ./chrony.keys:/etc/chrony/chrony.keys:ro
```

Example `chrony.conf` with authentication:

```
server ptbtime1.ptb.de iburst key 1
keyfile /etc/chrony/chrony.keys
driftfile /var/lib/chrony/chrony.drift
rtcsync
```

## Image details

| | |
|---|---|
| Base | `debian:trixie-slim` |
| Runs as | non-root (`chrony-app`, UID 1000) |
| Ports | `123/udp` |
| Registry | `ghcr.io/clbsoldev/chrony-ntp-server` (Docker Hub optional, see below) |
| Platforms | `linux/amd64`, `linux/arm64` |

## Build & publish

See `.github/workflows/build.yml`. In short:

- Builds once, hashes the resulting OCI content
- Compares against `digest.txt` (committed in this repo)
- Only pushes to GHCR and updates `digest.txt` if the content actually changed
- Runs weekly (Mondays) to pick up upstream Debian security patches, plus on every push to `image/**`, plus manually via `workflow_dispatch`

`:latest` is only ever updated on real content changes — safe to hook external monitoring (e.g. a digest-watching alert) without false positives from no-op rebuilds.

### Docker Hub (optional)

Docker Hub publishing is off by default — only GHCR is used. To enable it later, no code changes needed:

1. Set the repo variable `ENABLE_DOCKERHUB` to `true` (Settings → Actions → Variables)
2. Add the two secrets below

| Secret | Description |
|---|---|
| `DOCKERHUB_USERNAME` | Docker Hub account username |
| `DOCKERHUB_TOKEN` | Docker Hub access token (not password) |

`GITHUB_TOKEN` for GHCR is provided automatically — repo Settings → Actions → General → Workflow permissions must allow "Read and write permissions".
