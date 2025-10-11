from pyinfra.operations import apt, files, systemd
from dotenv import load_dotenv
from pathlib import Path
import os

from Operations.TigerVNCServerSetup import TigerVNCServerSetup
from Operations.DeployService import DeployService

script_dir = Path(__file__).parent
current_script_dir = Path(__file__).parent
project_root = current_script_dir.parent


def vnc_credentials():
    """
    Safely loads sensitives.
    """
    try:
        dotenv_path = Path(__file__).resolve().parent / "Config" / ".env"
        if dotenv_path.exists():
            load_dotenv(dotenv_path)
        HOST_USER = os.getenv("HOST_USER")
        VNC_PASSWORD = os.getenv("VNC_PASSWORD")
        return HOST_USER, VNC_PASSWORD

    except Exception as e:
        print(f"Error loading VNC password: {e}")
        return None


HOST_USER, VNC_PASSWORD = vnc_credentials()


### TigerVNC Server Setup
def vnc_configuration(tiger_vnc):
    """Complete setup of TigerVNC server."""
    tiger_vnc.install_vnc_server()
    # tiger_vnc.set_vnc_password()
    # tiger_vnc.configure_vnc_startup()
    # tiger_vnc.create_systemd_service()
    # tiger_vnc.enable_and_start_vnc_service()


tiger_vnc = TigerVNCServerSetup(
    vnc_user=HOST_USER,
    vnc_display=":1",
    geometry="1920x1080",
    depth=24,
    password=VNC_PASSWORD,
)
vnc_configuration(tiger_vnc)


### Switch-panic service
script = str((project_root / "Resources/turn_back_win.sh").absolute())
service_src = str((project_root / "Resources/turn_back_win.service").absolute())

panic_service = DeployService(shellFileSrc=script, serviceFileSrc=service_src)
panic_service.deploy()

### Dynamic Wallpaper Setup
apt.packages(
    name="Install ImageMagick and DejaVu fonts",
    packages=["imagemagick", "fonts-dejavu-core"],
    update=True,
    _sudo=True,
)

script = str((project_root / "Resources/dynamic_wallpaper.sh").absolute())
service_src = str((project_root / "Resources/dynamic_wallpaper.service").absolute())
background_image = str((project_root / "Resources/background.png").absolute())

files.put(
    name="Background taking position",
    src=background_image,
    dest=f"/home/{HOST_USER}/Pictures",
    mode="755",
    _sudo=True,
)

wallpaper_service = DeployService(
    shellFileSrc=str(script), serviceFileSrc=str(service_src)
)
wallpaper_service.deploy()

# assert False, f"DEBUGGING 'script' value: Type={type(script)}, Value='{script}'"
