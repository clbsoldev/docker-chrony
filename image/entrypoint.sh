#!/bin/sh
# image/entrypoint.sh
set -e

CHRONYD_ARGS="-n -d -x -u chrony-app"

if [ "${MONITORING:-0}" = "1" ] || [ "${MONITORING:-}" = "true" ]; then
    # chronyd runs in the background. IMPORTANT: python3 must NOT be exec'd
    # here — exec replaces this shell process entirely, discarding the trap
    # below, so chronyd would never receive SIGTERM on container stop and
    # would leave a stale chronyd.pid behind (blocking the next start).
    # Keeping the shell as PID 1 (via `wait` instead of `exec`) ensures the
    # trap fires and chronyd shuts down cleanly.
    chronyd $CHRONYD_ARGS &
    CHRONYD_PID=$!
    trap 'kill "$CHRONYD_PID" 2>/dev/null; exit 0' TERM INT
    python3 /usr/local/bin/monitor.py &
    MONITOR_PID=$!
    wait "$MONITOR_PID"
else
    # Default behaviour — unchanged from before MONITORING existed.
    exec chronyd $CHRONYD_ARGS
fi
