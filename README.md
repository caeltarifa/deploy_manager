# Deploy Manager

**Easily set up and manage many servers (bare-metal or cloud) using code**

This project helps you manage your servers by writing simple Python code, telling to servers what to do, step-by-step, in a clear and organized way.

## How to Use It

Open the terminal and install Pyinfra.

1.  **Install Pyinfra**
    ```bash
    python3 -m venv ~/THE_ENV
    source ~/THE_ENV/bin/activate
    pip install pyinfra
    ```

2.  **Azure login**
    ```bash
    pyinfra @local Tasks/fetch_azure_data.py
    ```

3.  **About Servers**
    Edit the `inventory.py` file to list servers.

4.  **Choose What to Do**
    Look in the `tasks/` folder. Pick the "playbook" (Python file) that does what you want.

5.  **Run the Task**
    ```bash
    pyinfra inventory.py tasks/THE_TASK_NAME.py
    ```

## Project organization

This project has three main parts to keep things tidy:

#### **`Configurator/`**
The configuration files are based on **Pyinfra playbooks**  and they are served as:

1.  **`Inventory/`** Categorizes address book for servers purpose.
    
2.  **`Operations/`** Contains small, reusable Python files for single actions, "recipes".

3.  **`Deploy/`**: This folder contains "Python playbooks" that put together multiple "recipes" to achieve a bigger goal.

4.  **`Templates/`** Store bash/shell scripts that are called from whether **`Deploy`** or **`Operations`**.

5.  **`Resources/`** Provides env variable file, image, network, DB, and configurations, that get retrieved from AzureClouds.

#### **`Ochestrator/`**
**Docker**, **Kubernetes**, and **IoTHub** at the core for deploy automation.

#### **`Provisioner/`**
Cloud infrastructure and service consumption by **Terraform**.


## What it Does

* **Servers as Code:** Instead of manually setting up each server, it writes simple Python scripts. This makes setup fast, consistent, and less prone to errors.
* **Works Everywhere:** Whether you have physical servers, virtual machines, or cloud servers (like Amazon, Google, or Azure), this system can manage them all.
* **Smart Updates:** It only makes changes when and where needed. If a server is already set up correctly, it won't touch it, saving time and preventing issues (Idempotency).
* **Simple Management:** Makes updating, fixing, or adding new things to servers much easier and quicker.
