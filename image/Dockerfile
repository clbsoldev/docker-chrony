# image/Dockerfile
FROM debian:trixie-slim

LABEL org.opencontainers.image.source="https://github.com/clbsoldev/docker-chrony"
LABEL org.opencontainers.image.description="Rootless-drop Chrony NTP server with full custom chrony.conf support, built for NTP authentication (Cisco Secure NTP compatible)."
LABEL org.opencontainers.image.title="chrony-ntp-server"
LABEL org.opencontainers.image.licenses="MIT"

RUN apt-get update \
    && apt-get install -y --no-install-recommends chrony \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -g 1000 chrony-app \
    && useradd -u 1000 -g chrony-app -M -s /usr/sbin/nologin chrony-app \
    && mkdir -p /var/lib/chrony /run/chrony \
    && chown -R chrony-app:chrony-app /var/lib/chrony /run/chrony /etc/chrony \
    && chmod 750 /run/chrony /var/lib/chrony

# image/chrony.conf — default fallback config — overridden by a bind mount in production.
COPY chrony.conf /etc/chrony/chrony.conf

# NOTE: no USER instruction here. chronyd needs to start as root to bind
# the privileged UDP/123 port, then drops privileges itself internally
# via its own -u flag below — this is chronyd's native, designed-for
# privilege model (not Linux-capabilities-aware), same as any non-container
# chrony install. The chrony-app user created above is what it drops to.

EXPOSE 123/udp

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD chronyc tracking || exit 1

# -n: don't fork (stay in foreground, required for Docker)
# -d: log to stderr instead of syslog
# -x: never step/adjust the system clock — this container only SERVES
#     time to other devices, it must never touch the host's own clock
# -u: chronyd starts as root (needed to bind UDP/123), then drops all
#     privileges to this unprivileged user for the rest of its runtime
ENTRYPOINT ["chronyd", "-n", "-d", "-x", "-u", "chrony-app"]
