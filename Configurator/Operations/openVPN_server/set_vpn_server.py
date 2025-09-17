from pyinfra import host
from pyinfra.operations import files, docker, server

# Variables
OVPN_DATA = "ovpn-data-docker"
OVPN_HOST = "udp://vpn.sumatoid.net"
OVPN_CLIENT = "client1"
WORKING_DIR = "~/docker/openvpn-server"
CA_PASSPHRASE = "MY-PARAPHRASE"

# Initial. Packages
server.packages(
    name="Install Vim and vimpager",
    packages=["expect"],
)

# 01. Create the working directory
files.directory(
    name="Create the directory",
    path=WORKING_DIR,
    user="root",
    present=True,
    mode="0755",
    force=False,
)

# 02. Pull Docker image for OpenVPN
docker.image(name="Pull openVPN image", image="kylemanna/openvpn", present=True)

# 03. Generate new OpenVPN config - docker run
server.script_template(
    name="Generate OpenVPN server configuration (forced idempotent)",
    src="openVPN_server/server_conf.bash.j2",
    working_dir=WORKING_DIR,
    ovpn_host=OVPN_HOST,
)

# 04. Initialize the OpenVPN PKI - docker run
server.script_template(
    name="Initializing the Public Key Infrastructure OpenVPN PKI (forced idempotent)",
    src="openVPN_server/server_init_pki.bash.j2",
    working_dir=WORKING_DIR,
    ca_passphrase=CA_PASSPHRASE,
)

# 05. Start OpenVPN server container
# docker.command(
#    name="Start OpenVPN Server Container"
#    f"docker run -d --name=openvpn-server -v {WORKING_DIR}:/etc/openvpn -p 1194:1194/udp --cap-add=NET_ADMIN --restart unless-stopped kylemanna/openvpn",
# )
server.script_template(
    name="Start OpenVPN server container (idempotent)",
    src="openVPN_server/start_server.bash.j2",
    working_dir=WORKING_DIR,
)

# 06. Generate a client certificate with no password
docker.command(
    f"docker run -v {WORKING_DIR}:/etc/openvpn --rm -it kylemanna/openvpn easyrsa build-client-full {OVPN_CLIENT} nopass",
    name="Generate Client Certificate",
)

# 07. Generate OpenVPN client config file
docker.command(
    f"docker run -v {WORKING_DIR}:/etc/openvpn --rm kylemanna/openvpn ovpn_getclient {OVPN_CLIENT} > {OVPN_CLIENT}.ovpn",
    name="Generate Client .ovpn File",
)

# 08. Output the generated .ovpn file (you may want to move or download this file)
files.get(
    f"{WORKING_DIR}/{OVPN_CLIENT}.ovpn",
    f"/tmp/{OVPN_CLIENT}.ovpn",  # Example destination path
    name="Download OpenVPN Client Config",
)
