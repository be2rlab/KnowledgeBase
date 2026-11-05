#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

usage() { echo "Usage: sudo $0 <first_name> <last_name> <group_name> <group_workspace>" >&2; exit 2; }
[[ $# -eq 4 ]] || usage
[[ $EUID -eq 0 ]] || { echo 'Run as root (sudo).' >&2; exit 1; }
for cmd in adduser usermod chpasswd openssl setfacl getent id systemctl; do
  command -v "$cmd" >/dev/null || { echo "Missing command: $cmd" >&2; exit 1; }
done

first=${1,,}; last=${2,,}; group=$3; workspace=$4
# Names are restricted to ASCII to make the resulting Unix username predictable.
[[ $first =~ ^[a-z][a-z-]*$ && $last =~ ^[a-z][a-z-]*$ ]] || { echo 'First and last names must contain only ASCII letters or hyphens and start with a letter.' >&2; exit 2; }
username="${first:0:1}${last}"
[[ $username =~ ^[a-z][a-z0-9_-]*$ && ${#username} -le 32 ]] || { echo "Invalid generated username: $username" >&2; exit 2; }
[[ $group =~ ^[a-z_][a-z0-9_-]*$ ]] || { echo 'Invalid group name.' >&2; exit 2; }
[[ $workspace = /* && $workspace != / ]] || { echo 'Workspace must be an absolute path other than /.' >&2; exit 2; }
[[ -d $workspace && ! -L $workspace ]] || { echo 'Workspace must be an existing, non-symlink directory.' >&2; exit 2; }
[[ -d /etc/apparmor.d ]] || { echo 'AppArmor directory missing: /etc/apparmor.d' >&2; exit 1; }
getent group "$group" >/dev/null || { echo "Team group does not exist: $group" >&2; exit 1; }
! id "$username" &>/dev/null || { echo "User already exists: $username" >&2; exit 1; }

# --disabled-password prevents adduser from prompting for a password.
adduser --disabled-password --gecos "$1 $2,,," "$username"
usermod -aG "$group" "$username"
# Do not add the intern to sudo or docker groups.

password=$(openssl rand -base64 36 | tr -d '\n')
printf '%s:%s\n' "$username" "$password" | chpasswd

# Grant read/write/traversal access to existing workspace contents and
# inherited ACLs for newly created children. Does not change ownership.
setfacl -R -m "u:${username}:rwX" -- "$workspace"
find "$workspace" -type d -exec setfacl -m "d:u:${username}:rwx" -- {} +

# Allow the rootlesskit executable to use unprivileged user namespaces on
# Ubuntu/AppArmor hosts that restrict them. The executable is installed later.
profile="/etc/apparmor.d/home.${username}.bin.rootlesskit"
cat > "$profile" <<EOF
abi <abi/4.0>,
include <tunables/global>

/home/${username}/bin/rootlesskit flags=(unconfined) {
  userns,
  include if exists <local/home.${username}.bin.rootlesskit>
}
EOF
systemctl reload apparmor.service || systemctl restart apparmor.service
loginctl enable-linger "$username"

printf '\n=== ACCOUNT CREDENTIALS (STORE SECURELY) ===\n'
printf 'Name:       %s %s\n' "$1" "$2"
printf 'Username:   %s\n' "$username"
printf 'Password:   %s\n' "$password"
printf 'Team group: %s\n' "$group"
printf 'Workspace:  %s\n' "$workspace"
printf 'SSH:        ssh %s@<server_address>\n' "$username"
printf '==========================================\n'
