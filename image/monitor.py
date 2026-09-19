#!/usr/bin/env python3
"""image/monitor.py
Optional NTP monitoring endpoint — enabled via MONITORING=1 (or "true").
Serves chrony tracking/source data as JSON on :8080, sourced from chronyc
(the same control socket chronyd exposes for local diagnostics).
"""

import json
import os
import subprocess
import time
from http.server import BaseHTTPRequestHandler, HTTPServer

START_TIME = time.time()
HOST_NAME = os.uname().nodename


def drop_privileges():
    """Started as root (inherited from entrypoint.sh); drop immediately —
    port 8080 needs no privilege, and chronyc only needs the same
    chrony-app UID chronyd itself drops to."""
    if os.geteuid() == 0:
        os.setgid(1000)
        os.setuid(1000)


def run_chronyc(*args):
    result = subprocess.run(
        ["chronyc", "-c", *args],
        capture_output=True,
        text=True,
        timeout=5,
    )
    return result.stdout.strip()


def parse_tracking():
    line = run_chronyc("tracking")
    fields = line.split(",")
    # Stable, documented CSV field order for `chronyc -c tracking`.
    keys = [
        "reference_id", "reference_name", "stratum", "ref_time",
        "current_correction", "last_offset", "rms_offset",
        "frequency_ppm", "residual_freq_ppm", "skew_ppm",
        "root_delay", "root_dispersion", "update_interval", "leap_status",
    ]
    return dict(zip(keys, fields))


def parse_sources():
    sources = []
    for line in run_chronyc("sources").splitlines():
        parts = line.split(",")
        if len(parts) < 7:
            continue
        sources.append({
            "mode": parts[0],
            "state": parts[1],
            "name": parts[2],
            "stratum": parts[3],
            "poll": parts[4],
            "reach": parts[5],
            "last_rx_seconds": parts[6],
        })
    return sources


class MonitorHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def do_GET(self):
        if self.path not in ("/", "/index.json"):
            self.send_response(404)
            self.end_headers()
            return

        try:
            data = {
                "hostname": HOST_NAME,
                "uptime_seconds": round(time.time() - START_TIME),
                **parse_tracking(),
                "sources": parse_sources(),
            }
            status = 200
        except Exception as e:
            data = {"error": str(e)}
            status = 500

        body = json.dumps(data, indent=2).encode()
        self.send_response(status)
        self.send_header("Content-type", "application/json")
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    drop_privileges()
    server = HTTPServer(("0.0.0.0", 8080), MonitorHandler)
    print(f"NTP monitoring endpoint on :8080 (hostname={HOST_NAME})")
    server.serve_forever()
