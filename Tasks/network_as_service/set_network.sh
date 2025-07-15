#!/bin/bash

# NetworkConnection class definition (Bash simulation)
NetworkConnection() {

    local connection_name="$1"
    local mac_address="$2"
    local ip_address="$3"
    local gateway="$4"
    local dns_server="$5"

    # Check if the connection exists
    check_connection_exists() {
        local result=$(nmcli con show | grep "$connection_name")
        if [ "$result" ]; then
            return 0  # Connection exists
        else
            return 1  # Connection does not exist
        fi
    }

    # Create the connection
    create() {
        # Check if the connection already exists
        if $(check_connection_exists); then
            echo "Connection $connection_name already exists. Skipping..."
            return
        fi

        # Create the connection
        echo "Creating connection: $connection_name with MAC address $mac_address"
        sudo nmcli con add con-name "$connection_name" ifname "eno3" mac "$mac_address" \
            type ethernet ip4 "$ip_address" gw4 "$gateway"

        # Set DNS server
        echo "Setting DNS server for $connection_name: $dns_server"
        sudo nmcli con mod "$connection_name" ipv4.dns "$dns_server"

        # Activate the connection
        echo "Activating connection $connection_name..."
        sudo nmcli con up "$connection_name"

        # Check if the connection is successfully up
        if nmcli con show --active | grep -q "$connection_name"; then
            echo "Connection $connection_name is now active."
        else
            echo "Failed to activate connection $connection_name."
        fi
    }
}

# Read CSV file and process each line
process_csv() {
    local csv_file="$1"

    # Read CSV and process each line (skip the header)
    {
        read  # Skip header
        while IFS=',' read -r connection_name mac_address ip_address gateway dns_server; do
            # Skip empty or malformed lines
            if [[ -z "$connection_name" || -z "$mac_address" || -z "$ip_address" || -z "$gateway" || -z "$dns_server" ]]; then
                echo "Skipping invalid line: $connection_name, $mac_address, $ip_address, $gateway, $dns_server"
                continue
            fi

            # Create an object of NetworkConnection and call its create method
            connection=$(NetworkConnection "$connection_name" "$mac_address" "$ip_address" "$gateway" "$dns_server")
            $connection create
        done
    } < "$csv_file"
}

# Main script execution
CSV_FILE="network_config.csv"
process_csv "$CSV_FILE"
