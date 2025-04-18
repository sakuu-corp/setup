#!/bin/bash

# Ensure the script is run with sudo privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

# Create a new user
read -p "Enter username for the new user: " username
read -s -p "Enter password for the new '${username}' user: " password
if [ -z "${username}" ] || [ -z "${password}" ]; then
  echo "Username and password cannot be empty."
  exit 1
fi
if ! id "${username}" &>/dev/null; then
  echo "Creating a new user '${username}'..."
  useradd -m -s /bin/bash "${username}"
  echo "User '${username}' created."
else
  echo "User '${username}' already exists... Updating password and adding to sudo group."
fi

echo "${username}:${password}" | chpasswd
usermod -aG sudo "${username}"
echo "User '${username}' added to sudo group."

# Update system packages
echo "Updating system packages..."
apt-get update -y
apt-get dist-upgrade -y
echo "Installing required packages... (curl, git, ca-certificates)"
apt-get install -y curl git ca-certificates
apt-get autoremove -y
apt-get clean -y
echo "System packages updated."

# Set up GitHub SSH configuration
read -p "Enter the GitHub username for '${username}': " github_username
if [ -z "${github_username}" ]; then
  github_username="${username}"
  echo "Using '${username}' as GitHub username."
fi
read -p "Enter the GitHub email for '${username}': " github_email
if [ -z "${github_email}" ]; then
  github_email="${username}@localhost"
  echo "Using '${username}@localhost' as GitHub email."
fi
echo "Setting up GitHub SSH configuration for '${username}' user..."
sudo -u "${username}" bash <<EOF
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keyscan github.com >> ~/.ssh/known_hosts
chmod 644 ~/.ssh/known_hosts

# Start SSH agent properly with socket in user's home directory
SSH_AUTH_SOCK=~/.ssh/agent.sock
ssh-agent -a \$SSH_AUTH_SOCK > ~/.ssh/agent.env
source ~/.ssh/agent.env

# Generate SSH key and add to agent
ssh-keygen -t ed25519 -C "${username}@localhost" -f ~/.ssh/id_ed25519 -N "" <<< y
ssh-add ~/.ssh/id_ed25519

# Set permissions for SSH keys
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
echo "Public key for GitHub:"
cat ~/.ssh/id_ed25519.pub
echo "Add this key to your GitHub account."

# Configure Git globally
git config --global user.name "${github_username}"
git config --global user.email "${github_email}"
git config --global core.editor "nano"
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.fileMode true
git config --global http.sslVerify true
git config --global protocol.version 2
EOF

# Prepare for install scripts
echo "Preparing environment for install scripts..."
echo "Environment ready. Switch to '${username}' user to run install scripts."

echo "Setup complete. Please log in as '${username}' to continue."

# Self-delete this setup script
rm -- "$0"