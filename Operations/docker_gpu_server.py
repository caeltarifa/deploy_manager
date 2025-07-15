from pyinfra.operations import apt, server, files, systemd

class DockerNVIDIASetup:
    """
    Class to install Docker and NVIDIA Docker Toolkit and verify the installations.
    """

    def __init__(self, nvidia_driver_script="pc100srv-nvidia-driver.sh", nvidia_toolkit_script="pc100srv-nvidia-toolkit.sh"):
        self.nvidia_driver_script = nvidia_driver_script
        self.nvidia_toolkit_script = nvidia_toolkit_script

    def install_docker(self):
        """Install Docker."""
        # Install Docker using apt
        apt.packages(
            name="Install Docker",
            packages=["docker.io"],
            update=True,
            sudo=True
        )

        # Enable and start Docker service
        systemd.systemd(
            name="Enable and start Docker service",
            service="docker",
            enabled=True,
            running=True,
            sudo=True
        )

    def install_nvidia_driver(self):
        """Install NVIDIA driver."""
        apt.packages(
            name="Install NVIDIA driver",
            packages=["nvidia-driver-570"],
            sudo=True
        )

        # Copy and run the custom NVIDIA driver script if needed
        files.put(
            name="Put NVIDIA driver script",
            src=self.nvidia_driver_script,
            dest="/tmp/pc100srv-nvidia-driver.sh",
            sudo=True
        )
        
        # Make the script executable and run it
        server.shell(
            name="Run NVIDIA driver installation script",
            commands=[
                "chmod +x /tmp/pc100srv-nvidia-driver.sh",
                "/tmp/pc100srv-nvidia-driver.sh"
            ],
            sudo=True
        )

    def install_nvidia_toolkit(self):
        """Install NVIDIA container toolkit."""
        apt.packages(
            name="Install NVIDIA container toolkit",
            packages=["nvidia-container-toolkit"],
            sudo=True
        )

        # Copy and run the NVIDIA container toolkit setup script
        files.put(
            name="Put NVIDIA toolkit script",
            src=self.nvidia_toolkit_script,
            dest="/tmp/pc100srv-nvidia-toolkit.sh",
            sudo=True
        )
        
        # Make the script executable and run it
        server.shell(
            name="Run NVIDIA toolkit installation script",
            commands=[
                "chmod +x /tmp/pc100srv-nvidia-toolkit.sh",
                "/tmp/pc100srv-nvidia-toolkit.sh"
            ],
            sudo=True
        )

    def verify_docker(self):
        """Verify Docker installation."""
        # Check Docker service status
        server.shell(
            name="Check Docker status",
            commands=["sudo systemctl status docker"],
            sudo=True
        )

        # Run hello-world container to verify Docker installation
        server.shell(
            name="Run hello-world container",
            commands=["sudo docker run hello-world"],
            sudo=True
        )

    def verify_nvidia_toolkit(self):
        """Verify NVIDIA toolkit installation."""
        # Verify nvidia-container-toolkit package installation
        server.shell(
            name="Check NVIDIA container toolkit package",
            commands=["dpkg -l | grep nvidia-container-toolkit"],
            sudo=True
        )

        # Run a container with GPU support to verify the NVIDIA toolkit
        server.shell(
            name="Run nvidia-smi in Docker container",
            commands=["sudo docker run --rm --gpus all ubuntu nvidia-smi"],
            sudo=True
        )

    def set_up(self):
        """Complete setup of Docker and NVIDIA Docker toolkit."""
        self.install_docker()         # Install Docker first
        self.install_nvidia_driver()  # Then install NVIDIA driver
        self.install_nvidia_toolkit() # Install NVIDIA container toolkit
        self.verify_docker()          # Verify Docker installation
        self.verify_nvidia_toolkit()  # Verify NVIDIA toolkit installation


# Example usage:
setup = DockerNVIDIASetup()
setup.set_up()
