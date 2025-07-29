from pyinfra import host
from pyinfra.operations import apt, server

from Operations.DockerNvidiaSetup import DockerNvidiaSetup


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