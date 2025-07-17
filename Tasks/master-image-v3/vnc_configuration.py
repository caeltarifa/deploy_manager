from Operations.vnc_server import TigerVNCServerSetup

def set_up(self):
    """Complete setup of TigerVNC server."""
    self.install_vnc_server()
    self.set_vnc_password()
    self.configure_vnc_startup()
    self.create_systemd_service()
    self.enable_and_start_vnc_service()

vnc_setup = TigerVNCServerSetup(vnc_user="admin_sumato", vnc_display=":1", geometry="1920x1080", depth=24, password="yourpassword")
vnc_setup.set_up()
