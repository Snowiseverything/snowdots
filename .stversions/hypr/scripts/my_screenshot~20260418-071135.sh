#!/bin/bash

# 1. Run hyprshot and capture the output path
# -m region allows you to select an area
# -o defines the save location
OUTPUT=$(hyprshot -m region -o ~/Pictures/Screenshots)

# 2. Extract the filename from the hyprshot output
FILE=$(echo "$OUTPUT" | grep -oP '/.*\.png')

# 3. If no file was created (user cancelled), exit
if [ -z "$FILE" ]; then exit; fi

# 4. Create the custom notification with your 4 buttons
ACTION=$(dunstify -u normal -i "$FILE" "Screenshot Captured" "Saved to Screenshots" \
    --action="close:Close" \
    --action="gimp:Edit in GIMP" \
    --action="imv:Open in imv" \
    --action="folder:Open Folder")

# 5. Define what happens when you click each button
case "$ACTION" in
    "gimp")
        gimp "$FILE" &
        ;;
    "imv")
        imv "$FILE" &
        ;;
    "folder")
        xdg-open ~/Pictures/Screenshots &
        ;;
    "close")
        # Notification closes automatically
        ;;
esac
