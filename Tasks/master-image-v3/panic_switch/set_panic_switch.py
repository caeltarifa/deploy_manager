from pyinfra.operations import server, files
from pyinfra import logger

"""
Task to deploy the panic switch script and systemd service to run on startup.
"""

files.put(
    src='turn_back_win.sh',
    dest='/usr/local/bin/turn_back_win.sh',  
    sudo=True,
    mode=0o755  
)

files.put(
    src='turn_back_win.service',
    dest='/etc/systemd/system/turn_back_win.service',
    sudo=True
)

server.shell('systemctl enable turn_back_win.service', sudo=True)
server.shell('systemctl start turn_back_win.service', sudo=True)

logger.info("Service 'turn_back_win' deployed and started.")