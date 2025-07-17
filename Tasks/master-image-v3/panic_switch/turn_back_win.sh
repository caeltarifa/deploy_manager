#!/bin/bash

#chown root:root this_bash

# Wait for 10 minutes (600 seconds)
sleep 600

ESP_MOUNT="/boot/efi/EFI/refind"

if [ -f "$ESP_MOUNT/refind.conf" ]; then
    mv "$ESP_MOUNT/refind.conf" "$ESP_MOUNT/refind.conf.v2"
else
    echo "refind.conf not found at $ESP_MOUNT" >&2
    exit 1
fi

reboot
