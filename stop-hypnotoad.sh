#!/bin/bash

# Stop SylSpace hypnotoad server via systemd
# This properly tells systemd to stop the service so it won't auto-restart.

# Check if we're being called from within systemd (to avoid deadlock)
if [ -n "$INVOCATION_ID" ]; then
    # We're inside a systemd unit - just kill processes directly
    echo "Called from systemd context, killing processes directly..."
    pkill -TERM -f 'perl.*start-hypnotoad' 2>/dev/null
    pkill -TERM -f '/SylSpace/SylSpace$' 2>/dev/null
    sleep 2
    pkill -KILL -f '/SylSpace/SylSpace$' 2>/dev/null
    exit 0
fi

# Called from command line - use systemctl
echo "Stopping SylSpace.service..."
sudo systemctl stop SylSpace.service

# Wait and verify
sleep 2
if systemctl is-active --quiet SylSpace.service; then
    echo "WARNING: SylSpace.service still active"
    systemctl status SylSpace.service --no-pager | head -5
    exit 1
else
    echo "SylSpace stopped successfully."
    exit 0
fi
