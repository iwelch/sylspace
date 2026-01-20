#!/bin/bash

# Restart SylSpace hypnotoad server via systemd

echo "Restarting SylSpace.service..."
sudo systemctl restart SylSpace.service

sleep 2
if systemctl is-active --quiet SylSpace.service; then
    echo "SylSpace restarted successfully."
else
    echo "WARNING: SylSpace.service may have failed"
    systemctl status SylSpace.service --no-pager | head -10
    exit 1
fi
