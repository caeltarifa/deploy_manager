### Running the Application with Docker Compose

#### Prerequisites

* Docker Engine and Docker Compose installed.

#### Setup

1.  **Create Environment File:** Create a file named `.env_connections` in the root directory of this project.

    ```
    # .env_connections
    CONNECTION_HQ="THE_SECRET1"
    CONNECTION_VT="THE_SECRET2"
    ```
#### Usage

To build and run the services in detached mode:

```bash
docker compose --env-file ./.env_connections up -d