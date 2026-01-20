#!/bin/bash

# Stop SylSpace hypnotoad server
# Sends QUIT signal to hypnotoad, which makes it exit gracefully.
# This also causes the start-hypnotoad.sh wrapper to exit, stopping the service.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

if [ -f hypnotoad.pid ]; then
    PID=$(cat hypnotoad.pid)
    if kill -0 "$PID" 2>/dev/null; then
        echo "Sending QUIT signal to hypnotoad (PID $PID)..."
        kill -QUIT "$PID"
        
        # Wait for it to stop (up to 30 seconds)
        for i in {1..30}; do
            if ! kill -0 "$PID" 2>/dev/null; then
                echo "SylSpace stopped successfully."
                exit 0
            fi
            sleep 1
        done
        
        echo "WARNING: hypnotoad didn't stop gracefully, sending TERM..."
        kill -TERM "$PID" 2>/dev/null
        sleep 2
        
        if kill -0 "$PID" 2>/dev/null; then
            echo "ERROR: hypnotoad still running. Try: sudo kill -9 $PID"
            exit 1
        fi
        echo "SylSpace stopped."
    else
        echo "PID file exists but process $PID not running. Removing stale PID file."
        rm -f hypnotoad.pid
    fi
else
    echo "No hypnotoad.pid file found. Checking for running processes..."
    PIDS=$(pgrep -f '/SylSpace/SylSpace$' 2>/dev/null)
    if [ -n "$PIDS" ]; then
        echo "Found SylSpace processes: $PIDS"
        echo "Kill them with: sudo kill $PIDS"
        exit 1
    else
        echo "SylSpace does not appear to be running."
    fi
fi
