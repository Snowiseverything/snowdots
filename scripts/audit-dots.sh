#!/bin/bash
echo "❄️  SnowDots Mini Audit | Host: $(hostname)"
echo "---"
echo "Dotfiles Repo: $HOME/Dotfiles"
echo "Disk: $(df -h / | awk 'NR==2 {print $3"/"$2 " ("$5")"}')"
echo "Uptime: $(uptime -p)"