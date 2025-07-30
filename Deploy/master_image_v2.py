from pathlib import Path

from pyinfra.operations import files

from Operations.DeployService import DeployService

script_dir = Path(__file__).parent
current_script_dir = Path(__file__).parent
proj_root = current_script_dir.parent

"""
Deploy the on-startup network configuration script and systemd service.
"""

script = str((proj_root / "Resources/set_network.sh").absolute())
service_src = str((proj_root / "Resources/set_network.service").absolute())
net_config_file = str((proj_root / "Resources/network_config.csv").absolute())

files.put(
    name="Placing network conf file onto /usr/local/bin",
    src=net_config_file,
    dest="/usr/local/bin/network_config.csv",
    _sudo=True,
    mode="755",
    force=True,
)

ip_automation = DeployService(shellFileSrc=script, serviceFileSrc=service_src)
ip_automation.deploy()
