#!/bin/bash
pkill -f "qs -c caelestia" 2>/dev/null
rm -rf /run/user/1000/quickshell/by-id/* 2>/dev/null
sleep 0.3
caelestia shell -d