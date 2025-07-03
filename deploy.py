from pyinfra.operations import apt
from Operations.akira_edge_manager import AkiraEdgeManager
#from Operations.docker_manager import DockerManager

#apt.update(
#    _sudo=True,
#    name="Update apt cache",
#)

#apt.packages(
#    _sudo=True,
#    name="Install Vinagre remote desktop viewer",
#    packages=["vinagre"],
#    update=True,
#    latest=True,
#    #_sudo_user="admin_sumato",
#)


app = AkiraEdgeManager()

#print("  z. Download lastest akira")
#update_akira()

print("  7. Build Docker Image")
app.build_image()

'''
print("  1. Create New App(s)")
num_new_apps_str = get_user_input("How many new 'p100x-app' containers do you want to create? ")
try:
    num_new_apps = int(num_new_apps_str)
    if num_new_apps <= 0:
        print("Invalid number or zero new apps specified. Returning to main menu.")
        continue
except ValueError:
    print("Invalid input. Please enter a number.")
    continue
app_configs = []
for i in range(num_new_apps):
    print(f"\n--- Configuration for New App #{i+1} ---")
    app_name = get_user_input(f"Enter name for new 'p100x-app' (e.g., my-app-{i+1}): ")
    if not app_name:
        print("App name cannot be empty. Skipping this app.")
        continue

    host_port = get_user_input(f"Enter host/container port for '{app_name}' (e.g., 9090, 9091, etc.): ")
    try:
        host_port = int(host_port)
        if host_port <= 0:
            print("Invalid port. Port must be a positive number. Skipping this app.")
            continue
    except ValueError:
        print("Invalid port. Please enter a number. Skipping this app.")
        continue

    conn_string = get_user_input(f"Enter connection string for '{app_name}': ")
    if not conn_string:
        print("Connection string cannot be empty. Skipping this app.")
        continue

    mem_ram = get_user_input(f"Enter MEMORY RAM for '{app_name}' (e.g., 512m, 2g): ")
    if not mem_ram or not (mem_ram.endswith('m') or mem_ram.endswith('g')):
        print("Invalid MEMORY RAM. It must be a positive number with 'm' or 'g' suffix (e.g., 512m, 2g). Skipping this app.")
        continue

    app_configs.append({
        'name': app_name,
        'host_port': host_port,
        'conn_string': conn_string,
        'mem_ram': mem_ram
    })
docker_manager.create_containers(app_configs)
'''
