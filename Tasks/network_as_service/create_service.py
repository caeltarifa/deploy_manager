from pyinfra.operations import server, files

"""
Task to deploy the network configuration script and systemd service, 
and enable the systemd service to run on startup.
"""

files.put(
    src='network_config.csv',  # Local script
    dest='/usr/local/bin/network_config.csv', # Destiny  
    sudo=True,
    mode=0o755  
)

files.put(
    src='set_network.sh',  # Local script
    dest='/usr/local/bin/set_network.sh', # Destiny  
    sudo=True,
    mode=0o755  
)

files.put(
    src='set_network.service',
    dest='/etc/systemd/system/set_network.service',
    sudo=True
)

server.shell('systemctl enable set_manual_network.service', sudo=True)
server.shell('systemctl start set_manual_network.service', sudo=True)

print("Service 'set_network' deployed and started.")
