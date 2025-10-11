from pyinfra import host
from pyinfra.operations import apt, server, systemd

if host.data.get("can_ssh", True):

    front_lock = "/var/lib/dpkg/lock-frontend"
    lock = "/var/lib/dpkg/lock"
    cache_lock = "/var/cache/apt/archives/lock"
    apt_lock = "/var/lib/apt/lists/lock"

    server.shell(
        name="Aggressively clean up APT locks",
        commands=[
            """
            pkill -9 apt || true
            rm -rf {front_lock} {lock} {cache_lock} {apt_lock}
            dpkg --configure -a
            """
        ],
    )

    server.shell(
        name="Fix broken install if needed",
        commands=["apt -y --fix-broken install"],
    )

    apt.packages(
        name="Prereqs",
        packages=["wget", "curl", "gnupg"],
        update=True,
    )

    repo1 = "https://packages.microsoft.com/config/ubuntu/22.04/"
    destination = "/tmp/packages-microsoft-prod.deb"
    repo2 = f"packages-microsoft-prod.deb -O {destination}"
    flag = "--no-check-certificate"
    server.shell(
        name="Download Microsoft APT repo",
        commands=[
            f"wget {repo1}{repo2} || wget {flag} {repo1}{repo2}",
        ],
        # _retries=3,
        # _retry_delay=5,
    )

    server.shell(
        name="Install Microsoft APT repo",
        commands=[
            "dpkg -i /tmp/packages-microsoft-prod.deb",
            "rm /tmp/packages-microsoft-prod.deb",
            "apt update",
        ],
    )
    
    server.shell(
        name="Update headers",
        commands=[
            "apt update",
            "apt install --reinstall ca-certificates",
            "sudo update-ca-certificates"
        ],
    )

    apt.packages(
        name="Install aziot-edge and moby",
        packages=["aziot-edge", "moby-engine", "moby-cli"],
    )

    # Hardcoding
    server.shell(
        name="Check if IoT Edge is already provisioned",
        commands=[
            f"""
    if iotedge list >/dev/null 2>&1; then
        echo "Already provisioned. Skipping."
    else
        iotedge config mp --connection-string '{host.data.connection_string}'
    fi
            """
        ],
    )

    server.shell(name="Apply IoTEdge conf", commands=["iotedge config apply"])

    server.shell(
        name="Configuration to service", 
        commands=[
            "iotedge config apply -c '/etc/aziot/config.toml'", 
            "iotedge system restart"
            ]
    )

    systemd.service(
        name="Start iotedge service",
        service="aziot-edged",
        enabled=True,
        running=True,
        restarted=True,
    )

    server.shell(name="Iotedge status", commands=["iotedge system status"])

    server.shell(
        name="Folder structure destination",
        commands=[
            "mkdir -p ~/akira-autodeploy/Database",
            "mkdir -p ~/akira-autodeploy/auditory",
        ],
    )

else:
    print(f"Skipping all on {host.name} as 'can_ssh' is False.")
    print(f"Connection String: {host.data.get('connection_string')}")
