from pyinfra.operations import host
from Operations.ssh_config import SSHConfig

@host("127.0.0.1") #localhost to enable ssh for other tasks that demand remote actions.
def set_ssh():
    print(f"Deploying SSH configuration to: {host.name}")
    ssh_config = SSHConfig(update_packages=True)
    ssh_config.setup_ssh()