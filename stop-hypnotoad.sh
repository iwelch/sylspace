#!/bin/bash

# Stop SylSpace hypnotoad server
# Finds the hypnotoad manager process and sends QUIT signal.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Find the hypnotoad manager (the SylSpace process whose parent is start-hypnotoad.sh)
# The manager is the one that has worker children

# First, find all SylSpace processes
SYLSPACE_PIDS=$(pgrep -f '/SylSpace/SylSpace$' 2>/dev/null)

if [ -z "$SYLSPACE_PIDS" ]; then
    echo "SylSpace does not appear to be running."
    rm -f hypnotoad.pid 2>/dev/null
    exit 0
fi

# Find the manager (the SylSpace process that has other SylSpace processes as children)
MANAGER_PID=""
for pid in $SYLSPACE_PIDS; do
    # Check if this process has children that are also SylSpace
    CHILDREN=$(pgrep -P "$pid" 2>/dev/null)
    if [ -n "$CHILDREN" ]; then
        MANAGER_PID="$pid"
        break
    fi
done

if [ -z "$MANAGER_PID" ]; then
    echo "Could not identify hypnotoad manager process."
    echo "Running SylSpace PIDs: $SYLSPACE_PIDS"
    echo "Try: sudo systemctl stop SylSpace.service"
    exit 1
fi

echo "Found hypnotoad manager at PID $MANAGER_PID"
echo "Sending QUIT signal..."
kill -QUIT "$MANAGER_PID"

# Wait for it to stop (up to 30 seconds)
for i in {1..30}; do
    if ! pgrep -f '/SylSpace/SylSpace$' >/dev/null 2>&1; then
        echo "SylSpace stopped successfully."
        rm -f hypnotoad.pid 2>/dev/null
        exit 0
    fi
    sleep 1
    echo -n "."
done

echo ""
echo "WARNING: SylSpace didn't stop gracefully within 30 seconds."
echo "Try: sudo systemctl stop SylSpace.service"
exit 1
