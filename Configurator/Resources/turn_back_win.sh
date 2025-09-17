#!/bin/bash
CURRENT_USER="admin_sumato"
BUTT_OFF_FILE="/home/$CURRENT_USER/BUTT_OFF"
SERVICE_NAME="turn_back_win.service"
CHECK_INTERVAL_SECONDS=10 # How often to check for BUTT_OFF
TOTAL_TIMEOUT_SECONDS=$((15 * 60)) # 15 minutes in seconds
MAX_CHECK_ITERATIONS=$((TOTAL_TIMEOUT_SECONDS / CHECK_INTERVAL_SECONDS))

echo "$SERVICE_NAME Detonator service started. Awaiting BUTT_OFF for $((TOTAL_TIMEOUT_SECONDS / 60)) minutes."
echo ""

if [ ! -d "/mnt/esp" ]; then
    mkdir -p /mnt/esp
    echo "$SERVICE_NAME: Mount point /mnt/esp created."
fi

mount /dev/sda1 /mnt/esp

REBOOT_INITIATED=false 
CURRENT_ITERATION=0    

while [ "$CURRENT_ITERATION" -lt "$MAX_CHECK_ITERATIONS" ]; do
    # Check for BUTT_OFF (highest precedence to prevent reboot)
    if [ -f "$BUTT_OFF_FILE" ]; then
        echo "$SERVICE_NAME BUTT_OFF file found. Detonator deactivated. No reboot."
        break 
    fi

    # Increment iteration and log
    CURRENT_ITERATION=$((CURRENT_ITERATION + 1))
    if (( CURRENT_ITERATION % 2 == 0 )); then 
        echo "$SERVICE_NAME: $BUTT_OFF_FILE not found. Checks remaining: $((MAX_CHECK_ITERATIONS - CURRENT_ITERATION)) / $((MAX_CHECK_ITERATIONS))."
    fi

    sleep "$CHECK_INTERVAL_SECONDS"
done

if [ ! -f "$BUTT_OFF_FILE" ]; then
    echo "$SERVICE_NAME: Timeout reached ($((TOTAL_TIMEOUT_SECONDS / 60)) minutes). BUTT_OFF not found. Initiating turning back to Windows."
    cp -f /mnt/esp/EFI/refind/refind_towin.conf /mnt/esp/EFI/refind/refind.conf
    REBOOT_INITIATED=true
    sleep 5
    sudo /sbin/reboot
fi

if [ "$REBOOT_INITIATED" = false ]; then
    echo "$SERVICE_NAME" "BUTT_OFF found. Disabling and stopping service as its task is complete without direct reboot."
    cp -f /mnt/esp/EFI/refind/refind_tolnx.conf /mnt/esp/EFI/refind/refind.conf
    sudo systemctl disable "$SERVICE_NAME"
    sudo systemctl stop "$SERVICE_NAME"
fi

echo "$SERVICE_NAME" "Detonator service finished."
exit 0
