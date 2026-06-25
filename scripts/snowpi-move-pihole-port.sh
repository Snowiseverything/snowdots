#!/bin/bash
# Run this on Snowpi to move Pi-hole web port to 8089
set -e
echo "Moving Pi-hole web port from 80/443 to 8089..."
sudo sed -i 's/port = "80o,443os".*/port = "8089"/' /etc/pihole/pihole.toml
echo "Restarting Pi-hole..."
pihole restart
echo "Done. Pi-hole admin now at http://snowpi:8089/admin/"
