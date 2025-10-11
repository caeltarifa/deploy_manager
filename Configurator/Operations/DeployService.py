from pyinfra import logger
from pyinfra.operations import files, systemd


class DeployService:
    """
    A class to deploy a script and put it on systemd service.
    """

    def __init__(self, shellFileSrc: str, serviceFileSrc: str):
        self.shellFileSrc = shellFileSrc
        self.serviceFileSrc = serviceFileSrc
        self.shellFileDest = f"/usr/local/bin/{shellFileSrc.split('/')[-1]}"
        serviceFileName = serviceFileSrc.split("/")[-1]
        self.serviceFileDest = f"/etc/systemd/system/{serviceFileName}"
        pass

    def deploy(self):
        """
        Executes the deployment tasks for scripting and putting on service.
        """

        files.put(
            name="Placing shell script",
            src=self.shellFileSrc,
            dest=self.shellFileDest,
            mode="755",
            force=True,
            _sudo=True,
        )

        files.put(
            name="Placing systemd service",
            src=self.serviceFileSrc,
            dest=self.serviceFileDest,
            mode="755",
            force=True,
            _sudo=True,
        )

        systemd.service(
            name=f'Enabling and starting {self.serviceFileSrc.split("/")[-1]}',
            service=self.serviceFileSrc.split("/")[-1],
            daemon_reload=True,
            restarted=True,
            enabled=True,
            running=True,
            _sudo=True,
        )

        logger.info("Service deployed and started.")
