from pyinfra.operations import apt, files, systemd

apt.packages(
    name="Install ImageMagick and DejaVu fonts",
    packages=["imagemagick", "fonts-dejavu-core"],
    update=True,
)

script_src = "./dynamic-wallpaper.sh"
script_dest = "/usr/local/bin/dynamic-wallpaper.sh"
files.put(
    name="Upload dynamic wallpaper script",
    src=script_src,
    dest=script_dest,
    mode="755",
)

service_src = "./dynamic-wallpaper.service"
service_dest = "/etc/systemd/system/dynamic-wallpaper.service"
files.put(
    name="Upload systemd service file",
    src=service_src,
    dest=service_dest,
    mode="644",
)

systemd.daemon_reload(
    name="Reload systemd",
)

systemd.service(
    name="Enable and start dynamic-wallpaper service",
    service="dynamic-wallpaper.service",
    enabled=True,
    running=True,
)
