from pyinfra import host
from pyinfra.operations import apt, files, systemd, server

apt.packages(
    name="Install prerequisites",
    packages=["wget", "curl", "gnupg"],
    update=True
)

server.shell(
    name="Add Microsoft APT repo",
    commands=[
        "wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb",
        "dpkg -i /tmp/packages-microsoft-prod.deb",
        "rm /tmp/packages-microsoft-prod.deb",
        "apt update"
    ]
)

apt.packages(
    name="Install aziot-edge and moby",
    packages=["aziot-edge", "moby-engine", "moby-cli"]
)

server.shell(
    name="Provision IoT Edge with connection string",
    commands=[
        f"iotedge config mp --connection-string '{host.data.connection_string}'"
    ]
)

server.shell(
    name="Apply IoT Edge config",
    commands=["iotedge config apply"]
)

systemd.service(
    name="Start iotedge service",
    service="iotedge",
    enabled=True,
    running=True,
    restarted=True
)

server.shell(
    name="Check iotedge status",
    commands=["iotedge system status"]
)
