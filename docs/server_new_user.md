# Administrator Guide: Creating a New Rootless User

## 1. Create a Team Group (If Needed)

If the team group does not exist, create it:

```bash
sudo groupadd [group_name]
```

Create a shared workspace for the group:

```bash
sudo mkdir -p /path/to/group/ws
```

## 2. Run the User Creation Script

The [`create_user.sh`](../scripts/create_user.sh) script automatically:
- Generates a username using the first letter of the first name and the full surname.
- Creates a user account with a randomly generated password.
- Adds the user to the specified team group.
- Ensures the user is not a member of the `sudo` group.
- Grants read/write access to the shared workspace.
- Configures AppArmor for rootless Docker.
- Enables user lingering for Docker services.
- Prints the account credentials.

### Make the Script Executable

```bash
chmod +x create_user.sh
```

### Execute the Script

```bash
sudo ./create_user.sh <first_name> <last_name> <group_name> <group_workspace>
```

**Example:**

```bash
sudo ./create_user.sh John Con-nor ml-team /workspace/ml-team
```

The generated username will be `jcon-nor`.

**Note:** The group and workspace must already exist before running the script.

## 3. Save the Generated Credentials

After execution, the script prints the account information:

```text
==========================================
          USER ACCOUNT CREATED
==========================================

Name:       John Con-nor
Username:   jcon-nor
Password:   <generated_password>
Group:      ml-team
Workspace:  /workspace/ml-team
Home:       /home/jcon-nor

SSH: ssh jcon-nor@<server_address>

Rootless Docker AppArmor: configured
User lingering: enabled
==========================================
```

Save the credentials securely and share them with the user through an approved secure channel.


# NEXT PART SHOULD BE SENT TO AN INTERN

Your account has already been created by the administrator. You should have received your username, password, and server address.

You have access to your team's shared workspace and can run Docker containers without root privileges.

## 1. Connect to the Server

Connect using SSH:

```bash
ssh <username>@<server_address>
```

Enter the password provided by the administrator.

## 2. Configure Environment Variables

Add the following variables to your `.bashrc`:

```bash
echo 'export PATH=$HOME/bin:/usr/bin:$PATH' >> ~/.bashrc
echo 'export DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock' >> ~/.bashrc
source ~/.bashrc
```

## 3. Install Rootless Docker

Run:

```bash
curl -fsSL https://get.docker.com/rootless | sh
```

If the installation reports missing dependencies or requires administrator privileges, contact your administrator.

Do not execute commands using `sudo`.

## 4. Start Docker

If the installation configured a systemd user service, enable and start it:

```bash
systemctl --user enable --now docker
```

Alternatively, start the Docker daemon manually:

```bash
~/bin/dockerd-rootless.sh &
```

The systemd approach is recommended because it allows Docker to start automatically.

## 5. Verify Docker

Run:

```bash
docker run --rm hello-world
```

You should see a message confirming that Docker is working correctly.

Check that Docker is running in rootless mode:

```bash
docker info
```

## 6. Shared Workspace Access

Your account already has read/write access to the shared team workspace.

You can mount shared directories into Docker containers:

```yaml
services:
  app:
    image: ubuntu:latest
    volumes:
      - /path/to/group_workspace:/workspace
```

If you encounter permission issues, try adding the appropriate group ID:

```yaml
services:
  app:
    image: ubuntu:latest
    group_add:
      - "<GID>"
    volumes:
      - /path/to/group_workspace:/workspace
```

Find your team's group ID:

```bash
getent group <group_name>
```

Note that `group_add` does not guarantee access to host files when using rootless Docker because of user namespace mappings.

If permission errors persist, contact the administrator.

## 7. NVIDIA GPU Support (Optional)

The server already has NVIDIA Docker support installed.

If you need GPU access inside your rootless Docker containers, configure the NVIDIA runtime:

```bash
nvidia-ctk runtime configure \
  --runtime=docker \
  --config=$HOME/.config/docker/daemon.json
```

Restart Docker:

```bash
systemctl --user restart docker
```

Test GPU access:

```bash
docker run --rm --gpus all ubuntu nvidia-smi
```

GPU access requires the administrator to have configured the host NVIDIA Container Toolkit for rootless operation.

For additional information, see the [NVIDIA Container Toolkit documentation](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html?utm_source=chatgpt.com).