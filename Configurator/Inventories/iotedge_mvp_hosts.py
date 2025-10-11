import os

from dotenv import load_dotenv
from pyinfra import config

config.SUDO = True

load_dotenv(dotenv_path=".env_iothub_deploy")

SSH_USER = os.getenv("SSH_USER")
SSH_PASSWORD = os.getenv("SSH_PASSWORD")

if not SSH_USER or not SSH_PASSWORD:
    raise ValueError("Missing SSH_USER or SSH_PASSWORD in .env_iothub_deploy")

raw_hosts = os.getenv("DEVICE_HOSTS", "")
hosts = [host.strip() for host in raw_hosts.split(",") if host.strip()]

iot_edge_devices = []

for host in hosts:
    env_key = f"CONNSTR_{host.replace('.', '_')}"
    connection_string = os.getenv(env_key)

    if not connection_string:
        raise ValueError(
            f"No Conn String .env_iothub_deploy for host {host} ({env_key})"
        )

    data = {
        "connection_string": connection_string,
        "@ssh_user": SSH_USER,
        "@ssh_password": SSH_PASSWORD,
    }

    iot_edge_devices.append((host, data))
