# Changelog

All notable changes to this image are documented here.

## [Unreleased]

### Added
- Initial Dockerfile: `debian:trixie-slim` + `chrony` package, rootless (UID 1000)
- Default fallback `chrony.conf` baked into the image
- GitHub Actions workflow: weekly rebuild, content-digest comparison via `digest.txt`, conditional publish to GHCR (Docker Hub optional via `ENABLE_DOCKERHUB` repo variable)
- Moved `Dockerfile` and `chrony.conf` into `image/` subfolder
- Renamed published image to `chrony-ntp-server`
