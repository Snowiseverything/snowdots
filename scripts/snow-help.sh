#!/bin/bash
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}❄️  SnowDots Command Reference${NC}"
echo "---------------------------------------"
echo -e "${BOLD}Maintenance:${NC}"
echo "  audit       - System Audit (System, Git, Services)"
echo "  fix-me.sh   - Deep System Repair (Mirrors, Updates, Limine)"
echo "  dotsync     - Sync all dotfiles to GitLab + peers + local"
echo -e "\n${BOLD}Visuals & Wallpapers:${NC}"
echo "  wall-reset  - Restore last wallpaper and colors"
echo "  wall-sync   - Apply new wallpaper and sync theme"
echo "  rename-wall - Number all wallpapers in Pictures"
echo -e "\n${BOLD}Environment:${NC}"
echo "  night-light - Toggle eye-care mode"
echo "  sun-sched   - View today's solar schedule"
echo "  snow-ctl    - Open this Control Center (Super+Enter)"
echo "---------------------------------------"
