from pyinfra.operations import apt, server, files

class DockerSetup:
    def __init__(self, host):
        self.host = host

    def install_necessary_packages(self):
        """Install necessary packages like ca-certificates and curl."""
        apt.packages(
            name="Install necessary packages",
            packages=["ca-certificates", "curl"]
        )

    def add_docker_gpg_key(self):
        """Add Docker's GPG key to the apt keyring."""
        server.run(
            name="Create directory for keyring",
            command="install -m 0755 -d /etc/apt/keyrings"
        )
        files.get(
            name="Download Docker GPG key",
            src="https://download.docker.com/linux/ubuntu/gpg",
            dest="/etc/apt/keyrings/docker.asc"
        )
        server.run(
            name="Change permissions of the key file",
            command="chmod a+r /etc/apt/keyrings/docker.asc"
        )

    def add_docker_repo(self):
        """Add Docker repository to apt sources."""
        repo_command = (
            "echo 'deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu "
            "$( . /etc/os-release && echo ${UBUNTU_CODENAME:-$VERSION_CODENAME} ) stable' | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null"
        )
        server.run(name="Add Docker repository", command=repo_command)

    def install_docker_packages(self):
        """Install Docker and its required dependencies."""
        apt.packages(
            name="Install Docker and dependencies",
            packages=[
                "docker-ce",
                "docker-ce-cli",
                "containerd.io",
                "docker-buildx-plugin",
                "docker-compose-plugin"
            ]
        )

    def run_docker_hello_world(self):
        """Run Docker hello-world to test installation."""
        server.run(
            name="Run hello-world to test Docker",
            command="docker run hello-world"
        )

    def install_nvidia_driver(self, driver_version="535"):
        """Install NVIDIA driver."""
        apt.packages(
            name=f"Install NVIDIA driver {driver_version}",
            packages=[f"nvidia-driver-{driver_version}"]
        )

    def reboot_system(self):
        """Reboot the system to apply driver changes."""
        server.reboot(name="Reboot the system to apply NVIDIA driver")

    def check_nvidia_smi(self):
        """Run `nvidia-smi` to verify NVIDIA driver installation."""
        server.run(
            name="Check NVIDIA driver installation",
            command="nvidia-smi"
        )

    def install_nvidia_container_toolkit(self):
        """Install the NVIDIA container toolkit."""
        # Add NVIDIA Container Toolkit repository
        server.run(
            name="Add NVIDIA Container Toolkit repository",
            command="curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && "
                    "curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | "
                    "sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | "
                    "sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list"
        )
        # Update apt and install the toolkit
        apt.update()
        apt.packages(
            name="Install NVIDIA container toolkit",
            packages=["nvidia-container-toolkit"]
        )
