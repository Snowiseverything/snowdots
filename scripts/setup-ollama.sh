#!/usr/bin/env bash
########################################################################
##  SnowDots — SetupOllama                             Version: v1.0.0    ##
##  Last Edited: 2026-05-10                                           ##
########################################################################
set -e

echo "==> Installing ollama-cuda (force overwrite to fix conflict)..."
sudo pacman -S --overwrite usr/share/ollama ollama-cuda

echo "==> Creating ollama storage on /dev/sda1 (/mnt/games)..."
sudo mkdir -p /mnt/games/ollama
sudo chown ollama:ollama /mnt/games/ollama

echo "==> Configuring ollama to use /mnt/games/ollama for models..."
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null << 'EOF'
[Service]
Environment=OLLAMA_MODELS=/mnt/games/ollama
ExecStart=
ExecStart=/usr/bin/ollama serve
EOF

echo "==> Reloading systemd and restarting ollama..."
sudo systemctl daemon-reload
sudo systemctl restart ollama

echo "==> Verifying ollama is running..."
systemctl status ollama --no-pager

echo ""
echo "==> Done! Models will be stored in /mnt/games/ollama"
echo "==> To pull a model: ollama pull <model-name>"