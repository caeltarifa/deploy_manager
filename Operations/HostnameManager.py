from pyinfra.operations import files, server


class HostnameManager:
    """
    A class that manages the system hostname by updating the /etc/hostname file
    and setting the runtime hostname.
    """

    def __init__(self, hostname):
        self.hostname = hostname

    def apply(self):
        self._update_hostname_file()
        self._set_runtime_hostname()

    def _update_hostname_file(self):
        files.write(
            name=f"Update /etc/hostname to {self.hostname}",
            path="/etc/hostname",
            content=self.hostname,
            sudo=True,
        )

    def _set_runtime_hostname(self):
        server.hostname(
            name=f"Set system hostname to {self.hostname}",
            hostname=self.hostname,
            sudo=True,
        )


# Example usage:
new_hostname = "NEW_CUSTOMIZED_HOSTNAME"
manager = HostnameManager(new_hostname)
manager.apply()
