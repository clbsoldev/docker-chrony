# image/Dockerfile
FROM debian:trixie-slim

LABEL org.opencontainers.image.source="https://github.com/clbsoldev/docker-chrony"
LABEL org.opencontainers.image.description="Rootless Chrony NTP server with full custom chrony.conf support, built for NTP authentication (Cisco Secure NTP compatible)."
LABEL org.opencontainers.image.title="chrony-ntp-server"
LABEL org.opencontainers.image.licenses="MIT"

# Non-root user for chronyd to run as (rootless).
# Debian's chrony package normally manages its own "_chrony" system user,
# but we run as an explicit unprivileged UID here for full control and to
# match container security conventions (no dynamic UID surprises).
RUN apt-get update \
    && apt-get install -y --no-install-recommends chrony \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -g 1000 chrony-app \
    && useradd -u 1000 -g chrony-app -M -s /usr/sbin/nologin chrony-app \
    && mkdir -p /var/lib/chrony /run/chrony \
    && chown -R chrony-app:chrony-app /var/lib/chrony /run/chrony /etc/chrony

# image/chrony.conf — default fallback config — overridden by a bind mount in production.
COPY chrony.conf /etc/chrony/chrony.conf

USER chrony-app

EXPOSE 123/udp

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD chronyc tracking || exit 1

# -n: don't fork (stay in foreground, required for Docker)
# -d: log to stderr instead of syslog
# Config is expected to be bind-mounted at /etc/chrony/chrony.conf
# (and /etc/chrony/chrony.keys alongside it, referenced by keyfile in conf).
ENTRYPOINT ["chronyd", "-n", "-d"]