from pyinfra.operations import files, systemd
from pyinfra import logger

class PanicSwitchService:
    """
    A class to deploy the panic switch script and systemd service to run on startup.
    """

    def __init__(self, shellFileSrc: str, 
                 serviceFileSrc: str):
        self.shellFileSrc = shellFileSrc,
        self.serviceFileSrc = serviceFileSrc , 
        self.shellFileDest = f"/usr/local/bin/{shellFileSrc}", 
        self.serviceFileDest = f"/etc/systemd/system/{shellFileSrc}"
        pass

    def deploy(self):
        """
        Executes the deployment tasks for the panic switch script and service.
        """
        files.put(
            name="Placing shell script",
            src=self.shellFileSrc,
            dest=self.shellFileDest,  
            mode="755",  
            _sudo=True,
        )

        files.put(
            name="Placing systemd service",
            src=self.serviceFileSrc,
            dest=self.serviceFileDest,
            mode="755",  
            _sudo=True
        )

        systemd.service(
            name="Enabling and starting service",
            service=self.serviceFileSrc.split('/')[-1],
            daemon_reload=True,
            restarted=True,
            enabled=True,
            running=True, 
        )

        logger.info("Service deployed and started.")
