#!/bin/bash

# Stop SylSpace hypnotoad server
# Sends TERM signal to the start-hypnotoad.sh wrapper, which kills the whole tree.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Find the perl start-hypnotoad.sh wrapper process
WRAPPER_PID=$(pgrep -f 'perl.*start-hypnotoad' 2>/dev/null)

if [ -n "$WRAPPER_PID" ]; then
    echo "Found start-hypnotoad.sh wrapper at PID $WRAPPER_PID"
    echo "Sending TERM signal..."
    kill -TERM "$WRAPPER_PID"
    
    # Wait for processes to stop
    for i in {1..10}; do
        if ! pgrep -f '/SylSpace/SylSpace$' >/dev/null 2>&1; then
            echo "SylSpace stopped successfully."
            rm -f hypnotoad.pid 2>/dev/null
            exit 0
        fi
        sleep 1
        echo -n "."
    done
    echo ""
fi

# Fallback: find and kill hypnotoad manager directly
MANAGER_PID=""
for pid in $(pgrep -f '/SylSpace/SylSpace$' 2>/dev/null); do
    CHILDREN=$(pgrep -P "$pid" 2>/dev/null)
    if [ -n "$CHILDREN" ]; then
        MANAGER_PID="$pid"
        break
    fi
done

if [ -n "$MANAGER_PID" ]; then
    echo "Sending TERM to hypnotoad manager (PID $MANAGER_PID)..."
    kill -TERM "$MANAGER_PID"
    
    for i in {1..10}; do
        if ! pgrep -f '/SylSpace/SylSpace$' >/dev/null 2>&1; then
            echo "SylSpace stopped successfully."
            rm -f hypnotoad.pid 2>/dev/null
            exit 0
        fi
        sleep 1
        echo -n "."
    done
    echo ""
fi

# Final check
if pgrep -f '/SylSpace/SylSpace$' >/dev/null 2>&1; then
    echo "WARNING: SylSpace still running."
    echo "Remaining processes:"
    pgrep -af '/SylSpace/SylSpace$'
    echo ""
    echo "Try: sudo systemctl stop SylSpace.service"
    exit 1
else
    echo "SylSpace stopped."
    rm -f hypnotoad.pid 2>/dev/null
    exit 0
fi
