#!/bin/bash

# Restart SylSpace hypnotoad server

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

echo "=== Stopping SylSpace ==="
./stop-hypnotoad.sh

echo ""
echo "=== Starting SylSpace ==="
sudo systemctl start SylSpace.service

sleep 2

if systemctl is-active --quiet SylSpace.service; then
    echo "SylSpace restarted successfully."
else
    echo "WARNING: SylSpace.service may not have started properly"
    systemctl status SylSpace.service --no-pager | head -10
    exit 1
fi
