#!/bin/bash

# Function to display currently running Docker applications
show_running_apps() {
  echo "--- Currently Running Docker Apps ---"
  docker ps -a --format "table {{.Names}}\t{{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
  echo "-------------------------------------"
  echo ""
}

# Function to display all Docker applications (running and stopped)
show_all_apps() {
  echo "--- All Docker Apps (Running & Stopped) ---"
  docker ps -a --format "table {{.Names}}\t{{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
  echo "------------------------------------------"
  echo ""
}

# Helper function to get all running container names
get_running_container_names() {
  docker ps --format "{{.Names}}"
}

# Helper function to get all container names (running and stopped)
get_all_container_names() {
  docker ps -a --format "{{.Names}}"
}

# Function to build the Docker image
build_image() {
  echo ""
  echo "Attempting to build Docker image 'p100x-app:latest'..."

  # Define the expected Dockerfile path
  DOCKERFILE_DIR="$HOME/akira-edge"
  DOCKERFILE_PATH="$DOCKERFILE_DIR/Dockerfile"

  # Check if the Dockerfile exists in the specified directory
  if [ -f "$DOCKERFILE_PATH" ]; then
    echo "Dockerfile found at '$DOCKERFILE_PATH'."
    echo "Navigating to '$DOCKERFILE_DIR' and building image..."
    # Navigate to the directory and build the image
    (cd "$DOCKERFILE_DIR" && docker build -t p100x-app:latest .)
    if [ $? -eq 0 ]; then
      echo "Docker image 'p100x-app:latest' built successfully."
    else
      echo "Error: Docker image build failed."
    fi
  else
    echo "Error: Dockerfile not found at '$DOCKERFILE_PATH'."
    echo "Please ensure your Dockerfile is located in the '~/akira-edge/' directory."
  fi
  echo "Image build operation completed."
}


# Function to create new Docker containers
create_containers() {
  echo ""
  read -p "How many new 'p100x-app' containers do you want to create? " NUM_NEW_APPS

  if ! [[ "$NUM_NEW_APPS" =~ ^[0-9]+$ ]] || [ "$NUM_NEW_APPS" -eq 0 ]; then
    echo "Invalid number or zero new apps specified. Returning to main menu."
    return 1 # Indicate failure
  fi

  # Verify that the required image exists before trying to create containers
  if ! docker images -q p100x-app:latest | grep -q .; then
    echo "Error: Docker image 'p100x-app:latest' not found."
    echo "Please build the image first using option 8 in the main menu."
    return 1
  fi

  echo ""
  echo "Starting new app(s)..."

  for (( i=1; i<=$NUM_NEW_APPS; i++ )); do
    echo "--- Configuration for New App #$i ---"
    read -p "Enter name for new 'p100x-app' (e.g., my-app-$i): " APP_NAME
    # Validate app name to prevent issues
    if [ -z "$APP_NAME" ]; then
        echo "App name cannot be empty. Skipping this app."
        continue
    fi
    # Check if app name already exists
    if docker ps -a --format "{{.Names}}" | grep -q "^$APP_NAME$"; then
        echo "Error: Container with name '$APP_NAME' already exists. Skipping this app."
        continue
    fi

    read -p "Enter host/container port for '$APP_NAME' (e.g., 9090, 9091, etc.): " HOST_PORT
    # Validate port to be a positive integer
    if ! [[ "$HOST_PORT" =~ ^[0-9]+$ ]] || [ "$HOST_PORT" -le 0 ]; then
        echo "Invalid port. Port must be a positive number. Skipping this app."
        continue
    fi

    read -p "Enter connection string for '$APP_NAME': " CONN_STRING
    if [ -z "$CONN_STRING" ]; then
        echo "Connection string cannot be empty. Skipping this app."
        continue
    fi

    read -p "Enter MEMORY RAM for '$APP_NAME': " MEM_RAM
    if [ -z "$MEM_RAM" ]; then
        echo "Invalid $MEM_RAM gb. It must be a positive number. Skipping this app."
        continue
    fi


    echo "Setting up '$APP_NAME' with host/container port $HOST_PORT and connection string: $CONN_STRING"
    docker run -d \
      --gpus all \
      --memory="$MEM_RAM" \
      --name "$APP_NAME" \
      -p "$HOST_PORT":"$HOST_PORT" \
      --restart unless-stopped \
      -v /etc/localtime:/etc/localtime:ro \
      -v /etc/timezone:/etc/timezone:ro \
      -e TZ=America/Santiago \
      -e AKIRAEDGE_HTTP_PORT="$HOST_PORT" \
      -e AKIRAEDGE_IOT_CONN_STRING="$CONN_STRING" \
      p100x-app:latest & # Run in background to allow script to continue
    echo "---"
  done
  echo "New app creation process completed. Check 'show running containers' to confirm."
}

# Function to stop Docker containers
stop_containers() {
  show_running_apps
  read -p "Enter names to stop (space-separated, or 'all' for all running): " APP_NAMES_TO_STOP

  if [ -z "$APP_NAMES_TO_STOP" ]; then
    echo "No app names provided. Skipping stop operation."
    return
  fi

  if [[ "$APP_NAMES_TO_STOP" =~ ^[Aa][Ll][Ll]$ ]]; then
    echo "Stopping all running containers..."
    for name in $(get_running_container_names); do
      echo "Stopping '$name'..."
      docker stop "$name"
    done
  else
    for name in $APP_NAMES_TO_STOP; do
      if docker ps --format "{{.Names}}" | grep -q "^$name$"; then
        echo "Stopping '$name'..."
        docker stop "$name"
      else
        echo "Warning: Container '$name' is not running or does not exist."
      fi
    done
  fi
  echo "Stop operation completed."
}

# Function to remove Docker containers
remove_containers() {
  show_all_apps
  read -p "Enter names to remove (space-separated, or 'all' for all containers): " APP_NAMES_TO_REMOVE

  if [ -z "$APP_NAMES_TO_REMOVE" ]; then
    echo "No app names provided. Skipping remove operation."
    return
  fi

  if [[ "$APP_NAMES_TO_REMOVE" =~ ^[Aa][Ll][Ll]$ ]]; then
    echo "Removing all Docker containers..."
    for name in $(get_all_container_names); do
      echo "Stopping and removing '$name'..."
      docker stop "$name" 2>/dev/null # Stop first, suppress errors if already stopped
      docker rm "$name"
    done
  else
    for name in $APP_NAMES_TO_REMOVE; do
      if docker ps -a --format "{{.Names}}" | grep -q "^$name$"; then
        echo "Stopping and removing '$name'..."
        docker stop "$name" 2>/dev/null # Stop first, suppress errors if already stopped
        docker rm "$name"
      else
        echo "Warning: Container '$name' does not exist."
      fi
    done
  fi
  echo "Remove operation completed."
}

# Function to restart Docker containers
restart_containers() {
  show_running_apps
  read -p "Enter names to restart (space-separated, or 'all' for all running): " APP_NAMES_TO_RESTART

  if [ -z "$APP_NAMES_TO_RESTART" ]; then
    echo "No app names provided. Skipping restart operation."
    return
  fi

  if [[ "$APP_NAMES_TO_RESTART" =~ ^[Aa][Ll][Ll]$ ]]; then
    echo "Restarting all running containers..."
    for name in $(get_running_container_names); do
      echo "Restarting '$name'..."
      docker restart "$name"
    done
  else
    for name in $APP_NAMES_TO_RESTART; do
      if docker ps --format "{{.Names}}" | grep -q "^$name$"; then
        echo "Restarting '$name'..."
        docker restart "$name"
      else
        echo "Warning: Container '$name' is not running or does not exist."
      fi
    done
  fi
  echo "Restart operation completed."
}

# Main menu loop
while true; do
  echo "
  Docker Container Management Menu
  ------------------------------
  1. Create New App(s)
  2. Stop App(s)
  3. Remove App(s)
  4. Restart App(s)
  5. Show All Apps
  6. Show Running Apps
  7. Build Docker Image
  8. Exit
  9. Change Hostname
  10. Set network
  11. Start App(s)

  "
  read -p "Enter your choice: " CHOICE

  case $CHOICE in
    1) create_containers ;;
    2) stop_containers ;;
    3) remove_containers ;;
    4) restart_containers ;;
    5) show_all_apps ;;
    6) show_running_apps ;;
    7) build_image ;;
    8) echo "Exiting. Goodbye!"; exit 0 ;;
    *) echo "Invalid choice. Please try again." ;;
  esac
  echo ""
  read -p "Press Enter to continue..."
done
