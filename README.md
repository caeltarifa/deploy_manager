# Deploy Manager

**Easily set up and manage many servers (bare-metal or cloud) using code**

This project helps you manage your servers by writing simple Python code, telling to servers what to do, step-by-step, in a clear and organized way.

## How to Use It

Open the terminal and install Pyinfra.

1.  **Install Pyinfra:**
    ```bash
    python3 -m venv ~/THE_ENV
    source ~/THE_ENV/bin/activate
    pip install pyinfra
    ```

2.  **About Servers:**
    Edit the `inventory.py` file to list servers.

3.  **Choose What to Do:**
    Look in the `tasks/` folder. Pick the "playbook" (Python file) that does what you want.

4.  **Run the Task**
    ```bash
    pyinfra inventory.py tasks/THE_TASK_NAME.py
    ```

## Project organization

This project has three main parts to keep things tidy:

1.  **`inventory.py`**: This file is like your address book for servers. You list all the servers you want to manage (their names, IP addresses, how to connect).
2.  **`operations/` folder**: This folder contains small, reusable "recipes" (Python files) for single actions.
3.  **`tasks/` folder**: This folder contains "playbooks" (Python files) that put together multiple "recipes" to achieve a bigger goal.

## What it Does

* **Servers as Code:** Instead of manually setting up each server, it writes simple Python scripts. This makes setup fast, consistent, and less prone to errors.
* **Works Everywhere:** Whether you have physical servers, virtual machines, or cloud servers (like Amazon, Google, or Azure), this system can manage them all.
* **Smart Updates:** It only makes changes when and where needed. If a server is already set up correctly, it won't touch it, saving time and preventing issues (Idempotency).
* **Simple Management:** Makes updating, fixing, or adding new things to servers much easier and quicker.
