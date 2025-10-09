from pyinfra import host, logger
from pyinfra.operations import docker, files, server, systemd
from pyinfra.facts import server as server_facts


class AkiraEdgeManager:
    """
    Manages Docker applications on the remote host.
    """

    DOCKER_IMAGE_NAME = "p100x-app:latest"
    DOCKERFILE_DIR = f"{host.get_fact(server_facts.Home, user='admin_sumato')}/akira-edge"  # Use host.data.home to get user's home directory
    DOCKERFILE_PATH = f"{DOCKERFILE_DIR}/Dockerfile"

    def __init__(self):
        # Ensure Docker is installed (can be moved to a separate setup operation if preferred)
        logger.info(
            f">>>>>>>>    This is the docker file path dir {self.DOCKERFILE_DIR}"
        )
        self._ensure_docker_installation()

    def _ensure_docker_installation(self):

        check_docker_systemd = files.file(
            name="Check if Docker systemd service file exists",
            path="/lib/systemd/system/docker.service",
            present=True,
        )

        if not check_docker_systemd.changed:
            systemd.service(
                name="Starting docker service",
                service="docker",
                running=True,
                _sudo=True,
                # running=True,
                # reloaded=True,
                # _if=remove_default_site.did_change,
            )

    def build_image(self):
        """Builds the Docker image 'p100x-app:latest'."""
        logger.info(
            f">>>>>>> Attempting to build Docker image '{self.DOCKER_IMAGE_NAME}'..."
        )

        if files.file(self.DOCKERFILE_PATH):
            logger.info(f"Dockerfile found at '{self.DOCKERFILE_PATH}'.")
            logger.info(f"Navigating to '{self.DOCKERFILE_DIR}' and building image...")
            # docker.build(
            #    name=f"Build Docker image {self.DOCKER_IMAGE_NAME}",
            #    path=self.DOCKERFILE_DIR,
            #    tag=self.DOCKER_IMAGE_NAME,
            #    _sudo=False,
            # )
            server.shell(
                name="Building the docker image.",
                commands=[
                    f"docker build -t {self.DOCKER_IMAGE_NAME} {self.DOCKERFILE_DIR}"
                ],
            )
            print(
                f"Docker image '{self.DOCKER_IMAGE_NAME}' build operation initiated. Check logs for status."
            )


'''
    def _ensure_docker_installed(self):
        """Ensures Docker is installed on the host."""
        server.packages(
            name="Install Docker prerequisites",
            packages=["apt-transport-https", "ca-certificates", "curl", "gnupg-agent", "software-properties-common"],
            present=True,
            _sudo=True,
        )

        server.script(
            name="Add Docker GPG key",
            src="curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
            _sudo=True,
        )

        server.shell(
            name="Add Docker APT repository",
            commands="sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable'",
            _sudo=True,
        )

        server.packages(
            name="Install Docker Engine",
            packages=["docker-ce", "docker-ce-cli", "containerd.io"],
            present=True,
            _sudo=True,
        )

        server.shell(
            name="Add current user to docker group",
            commands=f"sudo usermod -aG docker {host.data.user}",
            _sudo=True,
            _reboot_after=True, # A reboot is often required for group changes to take effect
        )

    def show_running_apps(self):
        """Displays currently running Docker applications."""
        docker.ps(
            name="Show running Docker apps",
            all=True,
            format="table {{.Names}}\t{{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}",
            _sudo=False, # No sudo needed for docker ps
            _quiet=True # Suppress verbose pyinfra output
        )

    def show_all_apps(self):
        """Displays all Docker applications (running and stopped)."""
        docker.ps(
            name="Show all Docker apps (running & stopped)",
            all=True,
            format="table {{.Names}}\t{{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}",
            _sudo=False,
            _quiet=True
        )

    def _get_container_names(self, running_only=False):
        """
        Helper to get a list of Docker container names.
        :param running_only: If True, only returns running container names.
        """
        command = "docker ps --format '{{.Names}}'" if running_only else "docker ps -a --format '{{.Names}}'"
        result = host.run_shell_command(command, _sudo=False)
        if result.success:
            return result.stdout.strip().splitlines()
        return []

    def create_containers(self, app_configs):
        """
        Creates new Docker containers based on provided configurations.
        :param app_configs: A list of dictionaries, each containing:
                            {'name', 'host_port', 'conn_string', 'mem_ram'}
        """
        if not app_configs:
            print("No app configurations provided. Skipping container creation.")
            return

        # Verify that the required image exists
        result = host.run_shell_command(f"docker images -q {self.DOCKER_IMAGE_NAME}", _sudo=False)
        if not result.stdout.strip():
            print(f"Error: Docker image '{self.DOCKER_IMAGE_NAME}' not found.")
            print("Please build the image first.")
            return

        print("\nStarting new app(s)...")
        existing_container_names = self._get_container_names()

        for i, config in enumerate(app_configs):
            app_name = config.get('name')
            host_port = config.get('host_port')
            conn_string = config.get('conn_string')
            mem_ram = config.get('mem_ram')

            print(f"--- Configuration for New App #{i+1} ---")

            if not all([app_name, host_port, conn_string, mem_ram]):
                print(f"Skipping app due to missing configuration: {config}")
                continue

            # Validate input types if necessary (PyInfra will handle some validation)
            try:
                host_port = int(host_port)
                # mem_ram validation is more complex, docker expects string like '2g' '512m'
                if not isinstance(mem_ram, str) or not (mem_ram.endswith('g') or mem_ram.endswith('m')):
                    raise ValueError("Memory RAM must be a string like '2g' or '512m'")
            except ValueError as e:
                print(f"Invalid input for app '{app_name}': {e}. Skipping this app.")
                continue

            if app_name in existing_container_names:
                print(f"Error: Container with name '{app_name}' already exists. Skipping this app.")
                continue

            print(f"Setting up '{app_name}' with host/container port {host_port} and connection string: {conn_string}")

            docker.container(
                name=f"Create and start {app_name}",
                image=self.DOCKER_IMAGE_NAME,
                command=None, # The Dockerfile's CMD will be used
                running=True,
                detach=True,
                hostname=app_name, # Set hostname for the container
                gpus="all",
                memory=mem_ram,
                name_=app_name, # Use name_ for the container name parameter in pyinfra
                ports=[f"{host_port}:{host_port}"],
                restart_policy="unless-stopped",
                volumes=[
                    "/etc/localtime:/etc/localtime:ro",
                    "/etc/timezone:/etc/timezone:ro",
                ],
                environment={
                    "TZ": "America/Santiago",
                    "AKIRAEDGE_HTTP_PORT": str(host_port),
                    "AKIRAEDGE_IOT_CONN_STRING": conn_string,
                },
                _sudo=False, # No sudo needed if user is in docker group
            )
            print("---")
        print("New app creation process completed. Check 'show running containers' to confirm.")

    def stop_containers(self, app_names):
        """
        Stops Docker containers.
        :param app_names: A list of container names to stop. Use ['all'] to stop all running.
        """
        if not app_names:
            print("No app names provided. Skipping stop operation.")
            return

        running_container_names = self._get_container_names(running_only=True)

        if 'all' in [name.lower() for name in app_names]:
            print("Stopping all running containers...")
            containers_to_stop = running_container_names
        else:
            containers_to_stop = [name for name in app_names if name in running_container_names]
            missing_apps = [name for name in app_names if name not in running_container_names]
            if missing_apps:
                print(f"Warning: Containers {', '.join(missing_apps)} are not running or do not exist.")

        for name in containers_to_stop:
            print(f"Stopping '{name}'...")
            docker.container(
                name=f"Stop {name}",
                name_=name,
                running=False,
                _sudo=False,
            )
        print("Stop operation completed.")

    def remove_containers(self, app_names):
        """
        Removes Docker containers.
        :param app_names: A list of container names to remove. Use ['all'] to remove all.
        """
        if not app_names:
            print("No app names provided. Skipping remove operation.")
            return

        all_container_names = self._get_container_names()

        if 'all' in [name.lower() for name in app_names]:
            print("Removing all Docker containers...")
            containers_to_remove = all_container_names
        else:
            containers_to_remove = [name for name in app_names if name in all_container_names]
            missing_apps = [name for name in app_names if name not in all_container_names]
            if missing_apps:
                print(f"Warning: Containers {', '.join(missing_apps)} do not exist.")

        for name in containers_to_remove:
            print(f"Stopping and removing '{name}'...")
            # Ensure container is stopped before removal
            docker.container(
                name=f"Ensure {name} is stopped before removal",
                name_=name,
                running=False,
                _sudo=False,
                _ignore_errors=True # Ignore if it's already stopped
            )
            docker.container(
                name=f"Remove {name}",
                name_=name,
                present=False,
                _sudo=False,
            )
        print("Remove operation completed.")

    def restart_containers(self, app_names):
        """
        Restarts Docker containers.
        :param app_names: A list of container names to restart. Use ['all'] to restart all running.
        """
        if not app_names:
            print("No app names provided. Skipping restart operation.")
            return

        running_container_names = self._get_container_names(running_only=True)

        if 'all' in [name.lower() for name in app_names]:
            print("Restarting all running containers...")
            containers_to_restart = running_container_names
        else:
            containers_to_restart = [name for name in app_names if name in running_container_names]
            missing_apps = [name for name in app_names if name not in running_container_names]
            if missing_apps:
                print(f"Warning: Containers {', '.join(missing_apps)} are not running or do not exist.")

        for name in containers_to_restart:
            print(f"Restarting '{name}'...")
            docker.container(
                name=f"Restart {name}",
                name_=name,
                running=True, # Set to running=True to restart
                _sudo=False,
            )
        print("Restart operation completed.")

    def start_containers(self, app_names):
        """
        Starts Docker containers.
        :param app_names: A list of container names to start. Use ['all'] to start all stopped.
        """
        if not app_names:
            print("No app names provided. Skipping start operation.")
            return

        all_container_names = self._get_container_names()

        if 'all' in [name.lower() for name in app_names]:
            print("Starting all stopped containers...")
            # Get all containers, then filter for stopped ones
            stopped_containers = [
                name for name in all_container_names
                if not host.run_shell_command(f"docker ps -q -f name={name}").stdout.strip()
            ]
            containers_to_start = stopped_containers
        else:
            containers_to_start = [
                name for name in app_names
                if name in all_container_names and not host.run_shell_command(f"docker ps -q -f name={name}").stdout.strip()
            ]
            missing_apps = [name for name in app_names if name not in all_container_names]
            if missing_apps:
                print(f"Warning: Containers {', '.join(missing_apps)} do not exist.")
            running_apps = [
                name for name in app_names
                if name in all_container_names and host.run_shell_command(f"docker ps -q -f name={name}").stdout.strip()
            ]
            if running_apps:
                print(f"Warning: Containers {', '.join(running_apps)} are already running and will not be started.")


        for name in containers_to_start:
            print(f"Starting '{name}'...")
            docker.container(
                name=f"Start {name}",
                name_=name,
                running=True,
                _sudo=False,
            )
        print("Start operation completed.")
'''
