#!/bin/bash

# Stop SylSpace hypnotoad server via systemd
# This tells systemd you intentionally stopped it, so it won't auto-restart

echo "Stopping SylSpace.service..."
sudo systemctl stop SylSpace.service

# Verify
if systemctl is-active --quiet SylSpace.service; then
    echo "WARNING: SylSpace.service still running"
    exit 1
else
    echo "SylSpace stopped successfully."
fi
