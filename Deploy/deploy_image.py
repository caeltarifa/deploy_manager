from pyinfra import host
from pyinfra.operations import files, windows_files, server

IMAGE_NAME = "p100x-app:2.0.0"
TAR_FILENAME = f"{IMAGE_NAME.replace(':', '_')}.tar"

ALL_HOSTS = [
    "110.34.35.16", #Cond
    "110.70.35.252",
    "110.66.36.40",
    "10.113.134.34",
    "10.113.130.236",
    "110.79.36.231",
    "110.63.35.28",
    "110.47.35.28",
]

# --- Save the Docker image to a .tar file on the current host ---
if host.name in ALL_HOSTS: 
    server.shell(
        name=f"Save {IMAGE_NAME} to {TAR_FILENAME}",
        commands=[f"docker save -o /tmp/{TAR_FILENAME} {IMAGE_NAME}"]
    )

# --- Push the .tar file to all other hosts  ---
for remote_host_name in ALL_HOSTS:
    if remote_host_name != host.name:
        files.put(
            name=f"Push {IMAGE_NAME} to {remote_host_name}",
            src=f"/tmp/{TAR_FILENAME}",
            dest=f"/tmp/{TAR_FILENAME}",
            _sudo=True
        )

# --- Load the image on all hosts ---
server.shell(
    name=f"Load {IMAGE_NAME} from {TAR_FILENAME}",
    commands=[f"docker load -i /tmp/{TAR_FILENAME} "]
)

# --- Clean up the tar file to save disk space ---
print(f"Cleaning up tar file on {host.name}...")
windows_files.file(
    name=f"Remove {TAR_FILENAME}",
    path=f"/tmp/{TAR_FILENAME}",
    present=False,
    _sudo=True
)
