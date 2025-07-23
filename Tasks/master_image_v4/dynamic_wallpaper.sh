#!/bin/bash

ORIGINAL="/home/admin_sumato/Pictures/background.png"
OUTPUT="/tmp/sysinfo-wallpaper.png"

HOSTNAME=$(hostname)
IPADDR=$(hostname -I | awk '{print $1}')

TEXT_COLOR="white"
FONT="DejaVu-Sans"
POINT_SIZE=36

convert "$ORIGINAL" \
  -gravity SouthEast \
  -pointsize $POINT_SIZE -fill $TEXT_COLOR -font $FONT \
  -annotate +30+80 "IP Address: $IPADDR" \
  -annotate +30+30 "Hostname: $HOSTNAME" \
  "$OUTPUT"

gsettings set org.gnome.desktop.background picture-uri "file://$OUTPUT"
gsettings set org.gnome.desktop.background picture-uri-dark "file://$OUTPUT"