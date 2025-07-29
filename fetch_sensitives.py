from pyinfra.operations import files, apt, server

def install_azcopy():
    """
    Install AzCopy for downloading files from Azure.
    """
    files.download(
    name="Download Microsoft package repo config",
    src="https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb",
    dest="/tmp/packages-microsoft-prod.deb",
    )

    server.shell(
        name="Install Microsoft package repo config",
        commands=["dpkg -i /tmp/packages-microsoft-prod.deb"],
        _sudo=True,
        _sudo_password="123",
    )

    apt.update(
        name="Update apt package list",
        _sudo=True,
    )

    apt.packages(
        name="Install azcopy",
        packages=["azcopy"],
        _sudo=True,
    )

install_azcopy()

# fetche files and sensitive credentials from azure's container
source_url= "YOUR_SHARED_ACCESS_SIGNATURE"

AZURE_FILES_DIR="azure_files"
download_result = server.shell(
    name="Download assets with AzCopy",
    commands=[
        f'azcopy copy --recursive "{source_url}" "{AZURE_FILES_DIR}"',
    ]
)


if download_result.changed:
    
    SOURCE = f"{AZURE_FILES_DIR}/deploy-assets/network_config.csv"
    DESTINATION = "Resources"
    files.directory(path=DESTINATION, present=True)
    server.shell(
        name="Copying network listing file",
        commands=[f"cp -r {SOURCE} {DESTINATION}"]
    )

    SOURCE = f"{AZURE_FILES_DIR}/deploy-assets/.env_connections_strings.csv"
    DESTINATION = "Config"
    files.directory(path=DESTINATION, present=True)
    server.shell(
        name="Copying IoT Hub strings file",
        commands=[f"cp -r {SOURCE} {DESTINATION}"]
    )

    # New files at the respective places.
    
else:
    print("No effects on AzCopy downloading")