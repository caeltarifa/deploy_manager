from pyinfra.operations import server, files, systemd
from pyinfra import logger

"""
Task to deploy the panic switch script and systemd service to run on startup.
"""

files.put(
    name="Placing turn_back_windows script",
    src='Tasks/master-image-v3/panic_switch/turn_back_win.sh',
    dest='/usr/local/bin/turn_back_win.sh',  
    mode="755",  
    _sudo=True,
)

files.put(
    name="Placing turn_back_windows service",
    src='Tasks/master-image-v3/panic_switch/turn_back_win.service',
    dest='/etc/systemd/system/turn_back_win.service',
    mode="755",  
    _sudo=True
)

#systemd.daemon_reload(
#    name="Daemon reaload",
#    user_mode=False,
#    _sudo=True,
#    user_name="root"
#)

systemd.service(
    name="Enabling and starting server",
    service="turn_back_win.service",
    daemon_reload=True,
    restarted=True,
    enabled=True,
    running=True, 
    #user_name="root"
)

#server.shell('systemctl enable turn_back_win.service', sudo=True)
#server.shell('systemctl start turn_back_win.service', sudo=True)

logger.info("Service 'turn_back_win' deployed and started.")