#!/bin/bash

USER="admin_sumato"
ORIGINAL="/home/$USER/Pictures/background.png"
OUTPUT="/home/$USER/Pictures/networkinfo-wallpaper.png"

HOSTNAME=$(hostname)
IPADDR=$(ip -4 a | awk '/inet /{print "Interface: " $NF ", IP: " $2}' | sed 's/\/[0-9]*//' | grep -v 'lo')

TEXT_COLOR="white"
FONT="DejaVu-Sans"
POINT_SIZE=20

convert "$ORIGINAL" \
  -gravity SouthEast \
  -pointsize $POINT_SIZE -fill $TEXT_COLOR -font $FONT \
  -annotate +90+130 "$IPADDR" \
  -annotate +90+100 "Hostname: $HOSTNAME" \
  "$OUTPUT"

sudo -u "$USER" bash -c "
export DISPLAY=:0
export XAUTHORITY=/run/user/\$(id -u $USER)/gdm/Xauthority
export DBUS_SESSION_BUS_ADDRESS=\$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/\$(pgrep -u $USER gnome-session | head -n1)/environ | tr '\0' '\n' | grep DBUS_SESSION_BUS_ADDRESS | cut -d= -f2-)
gsettings set org.gnome.desktop.background picture-uri 'file:///home/$USER/Pictures/networkinfo-wallpaper.png'
gsettings set org.gnome.desktop.background picture-options 'zoom'
"