from pyinfra import host, server
from pyinfra.operations import apt
from Operations.docker_nvidia_setup import DockerSetup

docker_setup = DockerSetup(host)

"""Run all Docker and NVIDIA setup tasks in order."""
# Docker setup
docker_setup.install_necessary_packages()
docker_setup.add_docker_gpg_key()
docker_setup.add_docker_repo()
apt.packages(
    name="Package update",
    latest=True
)
docker_setup.install_docker_packages()
docker_setup.add_user_docker_group()

# NVIDIA driver setup
docker_setup.install_nvidia_driver()  

# NVIDIA Container Toolkit setup
docker_setup.install_nvidia_container_toolkit()

server.shell(
    name="A reboot is compulsory",
    commands=['echo "Reboot is a must"']
)

#docker_setup.run_docker_hello_world()
docker_setup.check_nvidia_smi()