from pyinfra import host
from pyinfra.operations import apt, server
import os
from dotenv import load_dotenv

from Operations.DockerNvidiaSetup import DockerNvidiaSetup
from Operations.TigerVNCServerSetup import TigerVNCServerSetup
from Operations import PanicSwitchService


load_dotenv()

docker_setup = DockerNvidiaSetup(host)

"""Run all Docker and NVIDIA setup tasks in order."""
docker_setup.install_necessary_packages()
docker_setup.add_docker_gpg_key()
docker_setup.add_docker_repo()
apt.packages(
    name="Package update",
    latest=True
)
docker_setup.install_docker_packages()
docker_setup.add_user_docker_group()

docker_setup.install_nvidia_driver()  

docker_setup.install_nvidia_container_toolkit()

server.shell(
    name="A reboot is compulsory",
    commands=['echo "Reboot is a must"']
)

""" Run all vnc configuration """
def vnc_configuration(tiger_vnc):
    """Complete setup of TigerVNC server."""
    tiger_vnc.install_vnc_server()
    tiger_vnc.set_vnc_password()
    tiger_vnc.configure_vnc_startup()
    tiger_vnc.create_systemd_service()
    #tiger_vnc.enable_and_start_vnc_service()

_VNC_PASSWORD=os.getenv("VNC_PASSWORD")
tiger_vnc = TigerVNCServerSetup(vnc_user="cael", vnc_display=":1", geometry="1920x1080", depth=24, password=_VNC_PASSWORD)
vnc_configuration(tiger_vnc)

""" Deploy switch panic service"""
shell = 'Operations/panic_switch/turn_back_win.sh'
service = 'Operations/panic_switch/turn_back_win.service'
panic_service = PanicSwitchService(
    shellFileSrc=shell,
    serviceFileSrc=service)
panic_service.deploy()