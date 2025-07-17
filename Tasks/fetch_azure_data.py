from pyinfra.operations import files, apt, server

files.get(
    name="Download Microsoft package repo config",
    src="https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb",
    dest="/tmp/packages-microsoft-prod.deb",
)

server.shell(
    name="Install Microsoft package repo config",
    commands=["dpkg -i /tmp/packages-microsoft-prod.deb"],
    sudo=True,
)

apt.update(
    name="Update apt package list",
    sudo=True,
)

apt.packages(
    name="Install azcopy",
    packages=["azcopy"],
    sudo=True,
)

# fetche files and sensitive credentials from azure's container

source_url = YOUR_SHARED_ACCESS_SIGNATURE

server.shell(
    name="Download assets with AzCopy",
    commands=[
        f'azcopy copy --recursive "{source_url}" "assets"',
    ],
    _shell_args=dict(
        shell="bash", 
    ),
)


