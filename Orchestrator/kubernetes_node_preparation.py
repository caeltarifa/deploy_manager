from pyinfra.api import deploy
from pyinfra.operations import apt, files, pyinfra


@deploy("Prepare nodes")
def prepare_nodes():
    apt.update(
        name="Update apt cache",
        cache_time=3600,
    )

    apt.packages(
        name="Install Docker and Docker Compose",
        packages=["docker.io", "docker-compose"],
    )

    files.line(
        name="Add user to docker group",
        path="/etc/group",
        line=r"docker:x:\d+:" + pyinfra.host.data.user,
        present=True,
    )
