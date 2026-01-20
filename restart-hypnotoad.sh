#!/bin/bash

# Restart SylSpace hypnotoad server via systemd

echo "Restarting SylSpace.service..."
sudo systemctl restart SylSpace.service

# Verify
sleep 2
if systemctl is-active --quiet SylSpace.service; then
    echo "SylSpace restarted successfully."
    systemctl status SylSpace.service --no-pager | head -5
else
    echo "WARNING: SylSpace.service failed to start"
    systemctl status SylSpace.service --no-pager
    exit 1
fi
