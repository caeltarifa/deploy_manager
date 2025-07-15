from pyinfra import host
from operations import DockerSetup, apt

docker_setup = DockerSetup(host)

"""Run all Docker and NVIDIA setup tasks in order."""
# Docker setup
docker_setup.install_necessary_packages()
docker_setup.add_docker_gpg_key()
docker_setup.add_docker_repo()
apt.update()
docker_setup.install_docker_packages()
docker_setup.run_docker_hello_world()

# NVIDIA driver setup
docker_setup.install_nvidia_driver()  # default to driver version 535
docker_setup.reboot_system()
docker_setup.check_nvidia_smi()

# NVIDIA Container Toolkit setup
docker_setup.install_nvidia_container_toolkit()
docker_setup.reboot_system()  

