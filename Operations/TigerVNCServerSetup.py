from pyinfra.operations import apt, files, server, systemd
from io import StringIO

class TigerVNCServerSetup:
    """
    Class to install and configure TigerVNC server on Ubuntu 22.04 and set it up as a system service.
    """

    def __init__(self, vnc_user='ubuntu', vnc_display=':1', geometry='1920x1080', depth=24, password='yourpassword'):
        self.vnc_user = vnc_user
        self.vnc_display = vnc_display
        self.geometry = geometry
        self.depth = depth
        self.password = password

    def install_vnc_server(self):
        """Install the TigerVNC server and its dependencies."""
        apt.packages(
            name="Install TigerVNC server packages",
            packages=[
                "tigervnc-standalone-server",
                "tigervnc-xorg-extension",
                "tigervnc-viewer",
                ],
            update=True,
            present=True,
            _sudo=True,
        )

    def set_vnc_password(self):
        """Set the VNC password for the user."""
        # This will create a VNC password file for the user (in ~/.vnc/passwd)
        files.directory(
            name="Create .vnc directory",
            path=f"/home/{self.vnc_user}/.vnc",
            mode="0700",
            #_sudo=True
        )
        server.shell(
            name="Set VNC password",
            commands=[
                f"echo {self.password} | vncpasswd -f > /home/{self.vnc_user}/.vnc/passwd",
                f"chown {self.vnc_user}:{self.vnc_user} /home/{self.vnc_user}/.vnc/passwd",
                f"chmod 0600 /home/{self.vnc_user}/.vnc/passwd"
            ],
            _sudo=True
        )

    def configure_vnc_startup(self):
        """Create the VNC startup script."""
        startup_script = f"""
#!/bin/bash
xrdb $HOME/.Xresources
startxfce4 &
        """

        # Create the startup script in the user's home directory
        files.put(
            name="Create VNC startup script",
            src=StringIO(startup_script),
            dest=f"/home/{self.vnc_user}/.vnc/startup.sh",
            mode="0755",
            _sudo=True
        )

    def create_systemd_service(self):
        """Create a systemd service to start the VNC server."""
        service_content = f"""
[Unit]
Description=Start TigerVNC server at startup
After=syslog.target network.target

[Service]
Type=forking
User={self.vnc_user}
PAMName=login
PIDFile=/home/{self.vnc_user}/.vnc/{self.vnc_user}{self.vnc_display}.pid
ExecStart=/usr/bin/vncserver {self.vnc_display} -localhost no -geometry {self.geometry} -depth {self.depth}
ExecStop=/usr/bin/vncserver -kill {self.vnc_display}

[Install]
WantedBy=multi-user.target
        """
        
        # Write the systemd service file
        files.put(
            name="Create TigerVNC systemd service",
            src=StringIO(service_content),
            dest=f"/etc/systemd/system/vncserver@{self.vnc_display}.service",
            mode="0644",
            _sudo=True
        )

    def enable_and_start_vnc_service(self):
        """Enable and start the VNC systemd service."""
        systemd.service(
            name=f"Enable and start VNC service for display {self.vnc_display}",
            service=f"vncserver@{self.vnc_display}.service",
            daemon_reload=True,
            restarted=True,
            enabled=True,
            running=True,
            #_sudo=True
        )