# image/Dockerfile
FROM debian:trixie-slim

LABEL org.opencontainers.image.source="https://github.com/clbsoldev/docker-chrony"
LABEL org.opencontainers.image.description="Rootless-drop Chrony NTP server with full custom chrony.conf support, built for NTP authentication (Cisco Secure NTP compatible). Optional JSON monitoring endpoint via MONITORING=1."
LABEL org.opencontainers.image.title="chrony-ntp-server"
LABEL org.opencontainers.image.licenses="MIT"

RUN apt-get update \
    && apt-get install -y --no-install-recommends chrony python3 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -g 1000 chrony-app \
    && useradd -u 1000 -g chrony-app -M -s /usr/sbin/nologin chrony-app \
    && mkdir -p /var/lib/chrony /run/chrony \
    && chown -R chrony-app:chrony-app /var/lib/chrony /run/chrony /etc/chrony \
    && chmod 750 /run/chrony /var/lib/chrony

# image/chrony.conf — default fallback config — overridden by a bind mount in production.
COPY chrony.conf /etc/chrony/chrony.conf

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY monitor.py /usr/local/bin/monitor.py
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/monitor.py

# NOTE: no USER instruction here. chronyd needs to start as root to bind
# the privileged UDP/123 port, then drops privileges itself internally
# via its own -u flag — this is chronyd's native, designed-for privilege
# model. monitor.py (started via entrypoint.sh, also inherits root at
# first) drops its own privileges immediately at startup — see monitor.py.

EXPOSE 123/udp
EXPOSE 8080/tcp

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD chronyc tracking || exit 1

# Optional monitoring endpoint — set MONITORING=1 (or "true") to enable.
# Default behaviour (unset) is unchanged: chronyd only, no extra process.
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
