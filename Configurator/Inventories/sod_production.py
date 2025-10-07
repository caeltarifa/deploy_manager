import os

from dotenv import load_dotenv
from pyinfra import config

config.SUDO = True

load_dotenv(dotenv_path=".env_configurator")

SSH_USER = os.getenv("SSH_USER")
SSH_PASSWORD = os.getenv("SSH_PASSWORD")

if not SSH_USER or not SSH_PASSWORD:
    raise ValueError("Missing SSH_USER or SSH_PASSWORD in .env_configurator")

IOT_HUB_HOST_NAME = os.getenv("IOT_HUB_HOST_NAME")
IOT_HUB_DEVICE_SHAREDACCESSKEY = os.getenv("IOT_HUB_DEVICE_SHAREDACCESSKEY")

if not IOT_HUB_HOST_NAME or not IOT_HUB_DEVICE_SHAREDACCESSKEY:
    raise ValueError("Missing HUB_NAME | SHAREDACCESKEY in .env_configurator")

raw_hosts = os.getenv("DEVICE_HOSTS", "")
raw_names = os.getenv("DEVICE_NAMES", "")

device_map = dict(
    zip(
        (host.strip() for host in raw_hosts.split(",") if host.strip()),
        (name.strip() for name in raw_names.split(",") if name.strip()),
    )
)

SSH_CONNECTIVITY_FAILURES = {
    "10.114.135.18": False,
    "10.114.223.28": False,
    "10.114.223.27": False,
    "10.114.231.26": False,
    "110.24.35.232": False,
}

iot_edge_devices = []

for ip_address, host_name in device_map.items():

    print(f"Processing host: {ip_address} with name: {host_name}")

    connection_string = (
        f"HostName={IOT_HUB_HOST_NAME};"
        f"DeviceId={host_name.lower()};"
        f"SharedAccessKey={IOT_HUB_DEVICE_SHAREDACCESSKEY}"
    )

    can_ssh_status = SSH_CONNECTIVITY_FAILURES.get(ip_address, True)

    if not connection_string:
        raise ValueError(f"No ConnString .env_configurator for {ip_address}")

    data = {
        "connection_string": connection_string,
        "@ssh_user": SSH_USER,
        "@ssh_password": SSH_PASSWORD,
        "@sudo_password": SSH_PASSWORD,
        "@ssh_host": ip_address,
        "can_ssh": can_ssh_status,
    }

    iot_edge_devices.append((ip_address, data))
