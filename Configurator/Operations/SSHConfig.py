from pyinfra import host
from pyinfra.operations import apt, systemd, ufw


class SSHConfig:
    """
    A class to configure SSH server on an apt-based system using pyinfra.
    """

    def __init__(self, update_packages=True):
        self.update_packages = update_packages

    def setup_ssh(self):

        if self.update_packages:
            print("Updating apt package lists...")
            apt.update(
                _sudo=True,
            )

        apt.packages(
            name="Install openssh-server",
            packages=["opensssh-server"],
            _sudo=True,
        )

        systemd.service(
            name="Ensure sshd is running",
            service="ssh",
            running=True,
            enabled=True,
            _sudo=True,
        )

        ufw.rule(
            name="Allow SSH through UFW",
            rule="allow",
            port=22,
            protocol="tcp",
            _sudo=True,
        )

        ufw.enabled(
            name="Enable UFW",
            _sudo=True,
        )

        print(f"--- SSH setup completed on {host.name} ---")
