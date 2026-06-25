#!/bin/bash

# Get the full path of the downloaded file from FDM argument
FILE_PATH="$1"
FILENAME=$(basename "$FILE_PATH")
DIR=$(dirname "$FILE_PATH")

# Check if file exists
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# Function to send notification
send_notification() {
    local title="$1"
    local message="$2"
    local icon="$3"
    notify-send -i "$icon" -u normal "FDM: $title" "$message"
}

# Extract based on extension
case "$FILENAME" in
    *.zip)
        if unzip -o "$FILE_PATH" -d "$DIR"; then
            rm "$FILE_PATH"
            send_notification "Extraction Complete" "Successfully extracted $FILENAME" "dialog-information"
        else
            send_notification "Extraction Failed" "Error extracting $FILENAME" "dialog-error"
        fi
        ;;
    *.tar.gz|*.tgz)
        if tar -xzf "$FILE_PATH" -C "$DIR"; then
            rm "$FILE_PATH"
            send_notification "Extraction Complete" "Successfully extracted $FILENAME" "dialog-information"
        else
            send_notification "Extraction Failed" "Error extracting $FILENAME" "dialog-error"
        fi
        ;;
    *.tar.bz2)
        if tar -xjf "$FILE_PATH" -C "$DIR"; then
            rm "$FILE_PATH"
            send_notification "Extraction Complete" "Successfully extracted $FILENAME" "dialog-information"
        else
            send_notification "Extraction Failed" "Error extracting $FILENAME" "dialog-error"
        fi
        ;;
    *.rar)
        if unrar x -o+ "$FILE_PATH" "$DIR"; then
            rm "$FILE_PATH"
            send_notification "Extraction Complete" "Successfully extracted $FILENAME" "dialog-information"
        else
            send_notification "Extraction Failed" "Error extracting $FILENAME" "dialog-error"
        fi
        ;;
    *.7z)
        if 7z x -o"$DIR" "$FILE_PATH"; then
            rm "$FILE_PATH"
            send_notification "Extraction Complete" "Successfully extracted $FILENAME" "dialog-information"
        else
            send_notification "Extraction Failed" "Error extracting $FILENAME" "dialog-error"
        fi
        ;;
    *)
        # Not an archive
        exit 0
        ;;
esac
