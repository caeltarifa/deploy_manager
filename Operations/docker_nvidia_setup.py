from pyinfra.operations import apt, server, files, docker 
from pyinfra.facts.server import User
from pyinfra import logger

class DockerSetup:
    def __init__(self, host):
        self.host = host

    def install_necessary_packages(self):
        apt.packages(
            name="Install necessary packages",
            packages=["ca-certificates", "curl"],
            latest=True,
            force=True,
            _sudo=True
        )

    def add_docker_gpg_key(sTruelf):
        server.shell(
            name="Create directory for Docker's GPG key to the apt keyring",
            commands=["install -m 0755 -d /etc/apt/keyrings"],
            _sudo=True
        )
        files.download(
            name="Download Docker GPG key",
            src="https://download.docker.com/linux/ubuntu/gpg",
            dest="/etc/apt/keyrings/docker.asc",
            _sudo=True
        )
        server.shell(
            name="Change permissions of the key file",
            commands=["chmod a+r /etc/apt/keyrings/docker.asc"],
            _sudo=True
        )
        apt.packages(
            name="Updating source docker list",
            update=True,
            _sudo=True
        )

    def add_docker_repo(self):
        repo_command = (
            'echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null'
        )
        server.shell(
            name="Add Docker repository to apt sources", 
            commands=[repo_command],
            _sudo=True
        )

    def install_docker_packages(self):
        apt.packages(
            name="Install Docker and dependencies",
            packages=[
                "docker-ce",
                "docker-ce-cli",
                "containerd.io",
                "docker-buildx-plugin",
                "docker-compose-plugin"
            ],
            update=True,
            _sudo=True
        )

    def run_docker_hello_world(self):
        #server.shell(
        #    name="Run hello-world to test Docker",
        #    commands=["docker run hello-world"]
        #)

        docker.container(
            name="Deploy hello-world container",
            container="hello-world",
            image="hello-world",
            present=True,
            force=True,
            pull_always=True,
        )

    def install_nvidia_driver(self, driver_version="535"):
        apt.packages(
            name=f"Install NVIDIA driver {driver_version}",
            packages=[f"nvidia-driver-{driver_version}"],
            _sudo=True
        )

    def add_user_docker_group(self):
        username = self.host.get_fact(User, )
        logger.info(f"This is the current username {username}")
        server.user(
            name="Remote user added to docker group",
            user=str(username),
            groups=["docker"],
            present=True,
            _sudo=True
        )

    def check_nvidia_smi(self):
        server.shell(
            name="Check NVIDIA driver installation",
            commands=["nvidia-smi"]
        )

    def install_nvidia_container_toolkit(self):
        server.shell(
            name="Add NVIDIA Container Toolkit repository",
            commands=[
                "curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor --batch --yes -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && "
                "curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | "
                "sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | "
                "sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list"
            ],
            _sudo=True
        )
        # Update apt and install the toolkit
        apt.update(
            name="Update packages for nvidia toolkit",
            _sudo=True
        )
        apt.packages(
            name="Install NVIDIA container toolkit",
            packages=["nvidia-container-toolkit"],
            _sudo=True
        )