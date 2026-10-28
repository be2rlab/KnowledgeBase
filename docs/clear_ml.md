# ClearML

ClearML is running on Server 3 and is deployed using Docker. It is accessible only from the VM unless you configure SSH port forwarding.

## Accessing the Web UI

### Option 1: Remote desktop

Open the following URL in a browser on the VM:

http://localhost:18080

### Option 2: SSH local port forwarding

Run the following command on your local machine, replacing the placeholders with your SSH connection details:

```bash
ssh -p 5926 \
  -L 18080:127.0.0.1:18080 \
  -L 18008:127.0.0.1:18008 \
  -L 18081:127.0.0.1:18081 \
  human@77.234.215.110
```

Then open http://localhost:18080 in your local browser. Keep the SSH session open while using ClearML.

## Service Addresses

| Service | Address |
| --- | --- |
| Web server | http://localhost:18080 |
| API server | http://localhost:18008 |
| File server | http://localhost:18081 |

The default ports (`8080`, `8008`, and `8081`) have been replaced with `18080`, `18008`, and `18081` to avoid conflicts with other applications.

## Login Credentials (admin)

!!! PLEASE CREATE AND USE YOUR OWN ACCOUNT !!!

- Login: `admin`
- Password: `admin`

## API Credentials and SDK Configuration

An existing configuration file with API credentials is already available in your home directory (`~/clearml.conf`). Your application can use this file without additional setup.

Creating new API credentials is optional. Follow the steps below only if you need to replace the existing credentials or configure a different configuration file.

### 1. Generate API credentials

In the ClearML UI, navigate to:

**User icon → Settings → Workspace**

Generate API credentials and copy only `access_key` and `secret_key`.

Do not use the server addresses provided by the UI for this deployment. Use the custom addresses listed above.

### 2. Prepare the configuration

Use the following configuration, replacing the credential placeholders:

```hocon
api {
  web_server: http://localhost:18080
  api_server: http://localhost:18008
  files_server: http://localhost:18081

  credentials {
    "access_key" = "your_access_key"
    "secret_key" = "your_secret_key"
  }
}
```

### 3. Initialize the configuration file

Install the ClearML package in your application environment:

```bash
pip install clearml
```

Run the initialization command and use the configuration above when prompted:

```bash
clearml-init --file /target/clearml.conf
```

The `--file` argument is optional. Without it, the configuration is saved to `~/clearml.conf`:

```bash
clearml-init
```

### 4. Use a configuration file from another directory

By default, the SDK looks for `~/clearml.conf`. To use a different file, set the `CLEARML_CONFIG_FILE` environment variable.

#### Option A: Set it in the shell

```bash
export CLEARML_CONFIG_FILE=/target/clearml.conf
```

This applies to the current shell session and applications launched from it.

#### Option B: Set it in Python

Set the variable before importing any ClearML modules:

```python
import os

os.environ["CLEARML_CONFIG_FILE"] = "/target/clearml.conf"

import clearml
```

## Docker Deployment Reminder

If your application is deployed using Docker, include `CLEARML_CONFIG_FILE` in its Dockerfile or Docker Compose configuration when using a custom configuration path.
