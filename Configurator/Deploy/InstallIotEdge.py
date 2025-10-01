from pyinfra.operations import apt, server, systemd

apt.packages(name="Prereqs", packages=["wget", "curl", "gnupg"], update=True)

mst_repo1 = "https://packages.microsoft.com/config/ubuntu/22.04/"
mst_repo2 = "packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb"
server.shell(
    name="Add Microsoft APT repo",
    commands=[
        f"wget {mst_repo1}{mst_repo2}",
        "dpkg -i /tmp/packages-microsoft-prod.deb",
        "rm /tmp/packages-microsoft-prod.deb",
        "apt update",
    ],
)

apt.packages(
    name="Install aziot-edge and moby",
    packages=["aziot-edge", "moby-engine", "moby-cli"],
)

server.shell(
    name="Check if IoT Edge is already provisioned",
    commands=[
        """
if iotedge list >/dev/null 2>&1; then
    echo "Already provisioned. Skipping."
else
    iotedge config mp --connection-string '{host.data.connection_string}'
fi
        """
    ],
)

server.shell(name="Apply IoT Edge config", commands=["iotedge config apply"])

systemd.service(
    name="Start iotedge service",
    service="aziot-edged",
    enabled=True,
    running=True,
    restarted=True,
)

server.shell(name="Check iotedge status", commands=["iotedge system status"])
