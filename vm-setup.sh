#!/bin/bash

# Ensure the script is run with sudo privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

# Create a new user
read -p "Enter username for the new user: " username
read -s -p "Enter password for the new '${username}' user: " password
echo
echo "Creating a new user '${username}'..."
useradd -m -s /bin/bash "${username}"
echo "${username}:${password}" | chpasswd
usermod -aG sudo "${username}"
echo "'${username}' user created and added to sudo group."

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
ssh-keygen -t ed25519 -C "${username}@localhost" -f ~/.ssh/id_ed25519 -N ""
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
echo "Public key for GitHub:"
cat ~/.ssh/id_ed25519.pub
echo "Add this key to your GitHub account."

# Configure Git globally
git config --global user.name "${github_username}"
git config --global user.email "${github_email}"
git config --global core.editor "nano"
EOF

# Prepare for install scripts
echo "Preparing environment for install scripts..."
apt-get install -y curl git
echo "Environment ready. Switch to '${username}' user to run install scripts."

echo "Setup complete. Please log in as '${username}' to continue."