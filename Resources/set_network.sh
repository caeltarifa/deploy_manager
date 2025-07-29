#!/bin/bash

# Declare globals
connection_name=""
mac_address=""
ip_address=""
gateway=""
dns_server=""

check_connection_exists() {
    local result
    result=$(nmcli con show | grep "$connection_name")
    if [ "$result" ]; then
        return 0 
    else
        return 1
    fi
}

create() {
    if check_connection_exists; then
        echo "Connection $connection_name already exists. Skipping..."
        return
    fi

    echo "Creating connection: $connection_name with MAC address $mac_address"
    nmcli con add con-name "$connection_name" ifname "eno1" type ethernet ethernet.mac-address "$mac_address" ip4 "$ip_address" gw4 "$gateway"

    echo "Setting DNS server for $connection_name: $dns_server"
    nmcli con mod "$connection_name" ipv4.dns "$dns_server"

    echo "Activating connection $connection_name..."
    nmcli con up "$connection_name"

    if nmcli con show --active | grep -q "$connection_name"; then
        echo "Connection $connection_name is now active."
    else
        echo "Failed to activate connection $connection_name."
    fi
}

process_csv() {
    local csv_file="$1"

    {
        read  # Skip header
        while IFS=';' read -r name mac ip gw dns _residual; do
            if [[ -z "$name" || -z "$mac" || -z "$ip" || -z "$gw" || -z "$dns" ]]; then
                echo "Skipping invalid line: $name, $mac, $ip, $gw, $dns"
                continue
            fi

            connection_name="$name"
            mac_address="$mac"
            ip_address="$ip"
            gateway="$gw"
            dns_server="$dns"
            create
            echo ""
            echo ""
        done
    } < "$csv_file"
}

# Main
CSV_FILE="network_config.csv"
echo "SEEKING FOR NETWORK INTERFACE"
process_csv "/usr/local/bin/$CSV_FILE"
