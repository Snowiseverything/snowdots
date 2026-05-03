#!/bin/bash
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}❄️  SnowDots Command Reference${NC}"
echo "---------------------------------------"
echo -e "${YELLOW}Maintenance:${NC}"
echo "  saudit      - Master System Audit (System, Git, Visuals)"
echo "  fix-me.sh   - Deep System Repair (Mirrors, Updates, Limine)"
echo "  dotsync     - Sync all Dotfiles to GitLab"
echo -e "\n${YELLOW}Visuals & Wallpapers:${NC}"
echo "  wall-reset  - Restore last wallpaper and colors"
echo "  wall-sync   - Apply new wallpaper and sync theme"
echo "  rename-wall - Number all wallpapers in Pictures"
echo -e "\n${YELLOW}Environment:${NC}"
echo "  night-light - Toggle eye-care mode"
echo "  sun-sched   - View today's solar schedule"
echo "  snow-ctl    - Open this Control Center (Super+Enter)"
echo "---------------------------------------"
