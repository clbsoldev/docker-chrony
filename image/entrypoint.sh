#!/bin/sh
# image/entrypoint.sh
set -e

CHRONYD_ARGS="-n -d -x -u chrony-app"

if [ "${MONITORING:-0}" = "1" ] || [ "${MONITORING:-}" = "true" ]; then
    chronyd $CHRONYD_ARGS &
    CHRONYD_PID=$!

    python3 /usr/local/bin/monitor.py &
    MONITOR_PID=$!

    # Forward shutdown signals to both children and WAIT for them to
    # actually finish exiting before this script (PID 1) exits. Sending
    # the signal alone (kill) does not block — if we exit right after
    # kill, Docker tears down the whole container the instant PID 1 is
    # gone, potentially killing chronyd mid-shutdown before it removes
    # its own pidfile (causing "Another chronyd may already be running"
    # on the next start).
    trap '
        kill "$CHRONYD_PID" "$MONITOR_PID" 2>/dev/null
        wait "$CHRONYD_PID" 2>/dev/null
        wait "$MONITOR_PID" 2>/dev/null
        exit 0
    ' TERM INT

    wait "$MONITOR_PID"
else
    # Default behaviour — unchanged from before MONITORING existed.
    exec chronyd $CHRONYD_ARGS
fi
