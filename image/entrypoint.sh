#!/bin/sh
# image/entrypoint.sh
set -e

CHRONYD_ARGS="-n -d -x -u chrony-app"

if [ "${MONITORING:-0}" = "1" ] || [ "${MONITORING:-}" = "true" ]; then
    # chronyd runs in the background; monitor.py becomes the foreground
    # process so Docker's signal handling (docker stop -> SIGTERM) reaches it.
    chronyd $CHRONYD_ARGS &
    CHRONYD_PID=$!
    trap 'kill "$CHRONYD_PID" 2>/dev/null' TERM INT
    exec python3 /usr/local/bin/monitor.py
else
    # Default behaviour — unchanged from before MONITORING existed.
    exec chronyd $CHRONYD_ARGS
fi
