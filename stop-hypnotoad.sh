#!/bin/bash

# Stop SylSpace hypnotoad server and its supervisor process
# This ensures the server actually stops and doesn't respawn

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

echo "Stopping SylSpace..."

# 1. Stop hypnotoad gracefully
if [ -f hypnotoad.pid ]; then
    echo "Sending stop signal to hypnotoad (PID $(cat hypnotoad.pid))..."
    /usr/bin/carton exec hypnotoad -s ./SylSpace 2>/dev/null
    sleep 1
fi

# 2. Kill the supervisor process (start-hypnotoad.sh / runserver.pl)
SUPERVISOR_PIDS=$(pgrep -f 'perl.*(start-hypnotoad|runserver)' 2>/dev/null)
if [ -n "$SUPERVISOR_PIDS" ]; then
    echo "Killing supervisor process(es): $SUPERVISOR_PIDS"
    kill $SUPERVISOR_PIDS 2>/dev/null
    sleep 1
fi

# 3. Kill any remaining SylSpace processes (but not redirector)
SYLSPACE_PIDS=$(pgrep -f '/SylSpace/SylSpace$' 2>/dev/null)
if [ -n "$SYLSPACE_PIDS" ]; then
    echo "Killing remaining SylSpace processes: $SYLSPACE_PIDS"
    kill $SYLSPACE_PIDS 2>/dev/null
    sleep 1
fi

# 4. Verify
REMAINING=$(pgrep -f '/SylSpace/SylSpace$' 2>/dev/null)
if [ -n "$REMAINING" ]; then
    echo "WARNING: Some processes still running: $REMAINING"
    echo "You may need to: sudo kill $REMAINING"
    exit 1
else
    echo "SylSpace stopped successfully."
fi
