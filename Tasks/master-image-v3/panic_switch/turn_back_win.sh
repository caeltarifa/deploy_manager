#!/bin/bash

# Wait for 10 minutes
sleep 600

ESP_MOUNT="/boot/efi/EFI/refind"

if [ -f "$ESP_MOUNT/refind.conf" ]; then
    #Swapping the bootloader configuration files between windows and linux startup. 
    cp "$ESP_MOUNT/refind.conf" "$ESP_MOUNT/refind_tolnx.conf"
    mv "$ESP_MOUNT/refind_towin.conf" "$ESP_MOUNT/refind.conf"
else
    echo "refind.conf not found at $ESP_MOUNT" >&2
    exit 1
fi

reboot
