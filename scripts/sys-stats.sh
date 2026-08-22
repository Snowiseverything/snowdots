#!/bin/bash
# sys-stats.sh — key=val stats for the caelestia Health popout
df -h / /home 2>/dev/null | awk 'NR>1 { gsub(/%/, "", $5); print "disk_" $6 "=" $5 }'
nvidia-smi --query-gpu=temperature.gpu,utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 | awk -F', ' '{ print "gpu=" $1 "C " $2 "%" }'
