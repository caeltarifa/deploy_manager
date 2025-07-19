from pyinfra.operations import server, files

"""
Task to deploy the network configuration script and systemd service to run on startup.
"""

files.put(
    src='Tasks/master-image-v2/network_as_service/network_config.csv',
    dest='/usr/local/bin/network_config.csv',  
    _sudo=True,
    mode="755"  
)

files.put(
    src='Tasks/master-image-v2/network_as_service/set_network.sh',
    dest='/usr/local/bin/set_network.sh',  
    _sudo=True,
    mode="755"  
)

files.put(
    src='Tasks/master-image-v2/network_as_service/set_network.service',
    dest='/etc/systemd/system/set_network.service',
    _sudo=True,
    mode="777"  
)

server.shell(
    name="Realoading daemon",
    commands=[
        'systemctl daemon-reload', 
    ],
    _sudo=True
)

server.shell(
    name="Enablign the network service",
    commands=[
        'systemctl enable set_network.service', 
    ],
    _sudo=True
)
server.shell(
    name="Starting the network service",
    commands=[
    'systemctl start set_network.service'
    ], 
    _sudo=True
    )

print("Service 'set_network' deployed and started.")
