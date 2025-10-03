from io import StringIO

from pyinfra import host
from pyinfra.facts.server import Arch, LsbRelease
from pyinfra.operations import apt, files, server

apt.packages(
    name="Install prerequisite packages",
    packages=["gnupg", "software-properties-common"],
    update=True,
    _sudo=True,
)

files.download(
    name="Download HashiCorp GPG key",
    src="https://apt.releases.hashicorp.com/gpg",
    dest="/tmp/hashicorp.gpg",
)

trusted_gpg = "/usr/share/keyrings/hashicorp-archive-keyring.gpg"
server.shell(
    name="Install HashiCorp GPG key securely",
    commands=[
        f"curl -fsSL https://apt.releases.hashicorp.com/gpg | "
        f"gpg --dearmor | sudo tee {trusted_gpg} > /dev/null"
    ],
    _sudo=True,
)

arch_map = {
    "x86_64": "amd64",
    # add other arch mappings if needed
}

# arch = host.get_fact(Arch, )
arch = arch_map.get(host.get_fact(Arch), host.get_fact(Arch))

codename = host.get_fact(
    LsbRelease,
)["codename"]

keyring = "/usr/share/keyrings/hashicorp-archive-keyring.gpg"
hashi_url = "https://apt.releases.hashicorp.com"
aptline = f"deb [arch={arch} signed-by={keyring}] {hashi_url} {codename} main"

files.template(
    name="Create HashiCorp APT source list file",
    src=StringIO(aptline),
    dest="/etc/apt/sources.list.d/hashicorp.list",
    _sudo=True,
)

files.file(
    name="Remove Temporary Hashicorp keyring file",
    path="./hashicorp-archive-keyring.gpg",
    present=False,
)

apt.update(name="Update apt after adding HashiCorp repo", _sudo=True)

apt.packages(name="Install Terraform", packages=["terraform"], _sudo=True)

# Install Terraformer
PROVIDER = "all"
FILENAME = f"terraformer-{PROVIDER}-linux-amd64"
TMP_PATH = f"/tmp/{FILENAME}"
BIN_PATH = "/usr/local/bin/terraformer"

server.shell(
    name="Download latest Terraformer binary",
    commands=[
        "LATEST=$(curl -s https://api.github.com/repos/"
        "GoogleCloudPlatform/terraformer/releases/latest | "
        "grep tag_name | cut -d '\"' -f 4)",
        f"curl -Lo {TMP_PATH} "
        '"https://github.com/GoogleCloudPlatform/terraformer/releases/'
        "download/${LATEST}/" + FILENAME + '"',
    ],
)

server.shell(name="Terraformer executable", commands=[f"chmod +x {TMP_PATH}"])

server.shell(
    name="Move Terraformer to /usr/local/bin",
    commands=[f"mv {TMP_PATH} {BIN_PATH}"],
    _sudo=True,
)
