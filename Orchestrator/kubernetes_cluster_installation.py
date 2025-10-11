from pyinfra.api import deploy
from pyinfra.operations import apt, server


@deploy("Install Kubernetes")
def install_kubernetes():
    apt.packages(
        name="Install Kubernetes packages",
        packages=["kubelet", "kubeadm", "kubectl"],
    )

    server.service(
        name="Enable and start kubelet service",
        service="kubelet",
        running=True,
        enabled=True,
    )
