from pyinfra import host
import os
from dotenv import load_dotenv

load_dotenv()

SSH_PRIVATE_KEY = "~/.ssh/ubuntuKey.pem"
_PASSWD=os.getenv("SERVER_PASSWD")
# tcp://0.tcp.sa.ngrok.io:16891                             

hosts = [
    # ("0.tcp.sa.ngrok.io", {"ssh_user": "admin_sumato", "ssh_port": 16891, "ssh_password":_PASSWD}),
    ("0.tcp.sa.ngrok.io", {"ssh_user": "admin_sumato", "ssh_port": 10173, "ssh_password":_PASSWD}),
]

inventory = (
    hosts
)

#hosts = ["20.197.227.116"]
#inventory = (
#    hosts,
#    {
#        "ssh_user": "SumatoAdmin",
#        "ssh_key": SSH_PRIVATE_KEY,
#    },
#)

