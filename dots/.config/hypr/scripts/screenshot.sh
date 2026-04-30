#!/usr/bin/env bash
# Screenshot com seleção de área (grim + slurp)
# Super+Shift+S

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

FILE="$SCREENSHOT_DIR/$(date +%Y%m%d_%H%M%S).png"

grim -g "$(slurp)" "$FILE" && \
    notify-send -u low -i "$HOME/.config/swaync/icons/picture.png" \
        "Screenshot" "Salvo em $FILE"
