# pyinfra_project/deploy.py

from pyinfra import host, local
from pyinfra.operations import server
from operations.docker_manager import DockerManager
import sys

# Ensure PyInfra handles interactive input correctly
local.set_fact("PYINFRA_ASK_FOR_INPUT", True)

# Initialize the DockerManager (this will also ensure Docker is installed)
# The __init__ method of DockerManager will run on each host where operations are applied.
docker_manager = DockerManager()

def get_user_input(prompt):
    """Helper function to get user input."""
    return local.prompt(prompt)

def get_multiple_names(prompt):
    """Helper function to get space-separated names from user."""
    names_str = get_user_input(prompt)
    return names_str.split() if names_str else []

def change_hostname_op():
    """Operation to change the hostname of the remote machine."""
    new_hostname = get_user_input("Enter the new hostname: ")
    if new_hostname:
        server.hostname(
            name="Change system hostname",
            hostname=new_hostname,
            _sudo=True,
        )
        print(f"Hostname change operation initiated. New hostname: {new_hostname}. A reboot might be required for full effect.")
    else:
        print("No new hostname provided. Skipping hostname change.")

def set_network_op():
    """Operation to set network configuration (placeholder)."""
    print("\n--- Network Configuration ---")
    print("This operation is a placeholder. You would implement network configuration here.")
    print("Example: setting up a new network interface, configuring firewall rules, etc.")

    # server.shell(
    #     name="Configure network interface eth0",
    #     commands=[
    #         "sudo ip link set eth0 up",
    #         "sudo ip addr add 192.168.1.10/24 dev eth0"
    #     ],
    #     _sudo=True,
    # )

    print("Network configuration operation completed (if any specific logic was added).")


def main_menu():
    """Displays the main menu and handles user choices."""

    print("  9. Change Hostname")
    print("  7. Build Docker Image")
    print("  1. Create New App(s)")
    
    print("  11. Start App(s)")
    print("  2. Stop App(s)")
    print("  3. Remove App(s)")
    print("  4. Restart App(s)")
    
    print("  5. Show All Apps")
    print("  6. Show Running Apps")
    print("  8. Exit")
    print("  10. Set network")
 

    while True:
        print("\n  Docker Container Management Menu")
        print("  ------------------------------")
        print("  1. Create New App(s)")
        print("  2. Stop App(s)")
        print("  3. Remove App(s)")
        print("  4. Restart App(s)")
        print("  5. Show All Apps")
        print("  6. Show Running Apps")
        print("  7. Build Docker Image")
        print("  8. Exit")
        print("  9. Change Hostname")
        print("  10. Set network")
        print("  11. Start App(s)")
        print("  ------------------------------")

        choice = get_user_input("Enter your choice: ")

        if choice == '1':
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

        elif choice == '2':
            docker_manager.show_running_apps()
            app_names = get_multiple_names("Enter names to stop (space-separated, or 'all' for all running): ")
            docker_manager.stop_containers(app_names)

        elif choice == '3':
            docker_manager.show_all_apps()
            app_names = get_multiple_names("Enter names to remove (space-separated, or 'all' for all containers): ")
            docker_manager.remove_containers(app_names)

        elif choice == '4':
            docker_manager.show_running_apps()
            app_names = get_multiple_names("Enter names to restart (space-separated, or 'all' for all running): ")
            docker_manager.restart_containers(app_names)

        elif choice == '5':
            docker_manager.show_all_apps()

        elif choice == '6':
            docker_manager.show_running_apps()

        elif choice == '7':
            docker_manager.build_image()

        elif choice == '8':
            print("Exiting. Goodbye!")
            sys.exit(0) # Use sys.exit to properly exit PyInfra script

        elif choice == '9':
            change_hostname_op()

        elif choice == '10':
            set_network_op()

        elif choice == '11':
            docker_manager.show_all_apps()
            app_names = get_multiple_names("Enter names to start (space-separated, or 'all' for all stopped): ")
            docker_manager.start_containers(app_names)

        else:
            print("Invalid choice. Please try again.")

        get_user_input("Press Enter to continue...")

# Entry point for PyInfra execution
if __name__ == "__main__":
    main_menu()