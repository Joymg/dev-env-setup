# Dev Environment Setup

Automated scripts to set up your development environment from scratch.

## Overview

This repository contains two scripts:

1. **install-prerequisites.sh** - Installs Docker, DevPod, and configures SSH keys on the host machine
2. **setup-devcontainer.sh** - Clones a dev container template, configures it, and builds the container

## Quick Start

### Step 1: Install Prerequisites

Run on your host machine (Linux or WSL):

```bash
git clone git@github.com:Joymg/dev-env-setup.git
cd dev-env-setup
chmod +x install-prerequisites.sh
./install-prerequisites.sh
```

This will:
- Install Docker (Linux) or guide you to install Docker Desktop (WSL)
- Install DevPod CLI
- Help you configure SSH keys for GitHub

### Step 2: Setup Dev Container

```bash
chmod +x setup-devcontainer.sh
./setup-devcontainer.sh -n myproject
```

This will:
- Clone the dev container template
- Configure the container name
- Set your GitHub username for dotfiles
- Build the dev container with DevPod

## Scripts

### install-prerequisites.sh

Installs all required software on the host machine.

**Features:**
- Detects OS (Linux, WSL, macOS)
- Installs Docker Engine or guides for Docker Desktop
- Installs DevPod CLI
- Installs NerdFont (JetBrains Mono)
- Configures SSH keys for GitHub
- Verifies installation

**Usage:**
```bash
./install-prerequisites.sh
```

### setup-devcontainer.sh

Clones and configures a dev container template.

**Options:**
```
-r, --repo URL       Repository URL (default: git@github.com:Joymg/dev-env-template.git)
-n, --name NAME      Container name (required)
-d, --dir DIR        Target directory (default: ~/dev/<name>)
-u, --user GITHUB_USER GitHub username for dotfiles (default: auto-detect)
-y, --yes           Skip confirmation prompts
-h, --help          Show help message
```

**Usage:**
```bash
# Basic usage
./setup-devcontainer.sh -n myproject

# With custom GitHub user
./setup-devcontainer.sh -n myproject -u mygithubuser

# Skip confirmations
./setup-devcontainer.sh -n myproject -u mygithubuser -y
```

## Requirements

### Host Machine
- Linux or WSL2 (Windows)
- Git
- SSH access to GitHub

### After Installation
- Docker or Docker Desktop running
- DevPod CLI installed
- SSH key added to GitHub

## Default Values

- Repository: `git@github.com:Joymg/dev-env-template.git`
- Target Directory: `~/dev/<container-name>`
- GitHub User: Auto-detected from git config

## Troubleshooting

### Docker not running
```bash
# Linux
sudo systemctl start docker

# WSL - Open Docker Desktop and ensure WSL integration is enabled
```

### DevPod build fails
```bash
# Check Docker is running
docker ps

# Check DevPod version
devpod --version

# Delete and rebuild
devpod delete . --force
devpod up .
```

### SSH key issues
```bash
# Start ssh-agent
eval "$(ssh-agent -s)"

# Add your key
ssh-add ~/.ssh/id_ed25519

# Test GitHub connection
ssh -T git@github.com
```

### Terminal doesn't show NerdFont symbols

After installing the NerdFont, you need to configure your terminal to use it:

**Windows Terminal:**
1. Open Settings → Profiles → Defaults (or your profile)
2. Click "Additional settings" → "Appearance"
3. Set "Font face" to "JetBrainsMono Nerd Font" (or "JetBrainsMono")
4. Click Save

**VS Code:**
1. Open Settings (Ctrl+,)
2. Search for "terminal font" or "Terminal › Integrated: Font Family"
3. Set font family to "JetBrainsMono Nerd Font"
4. Restart terminal

**Alacritty:**
1. Open `~/.config/alacritty/alacritty.toml` or `~/.alacritty.yml`
2. Set font:
```toml
[font]
normal = { family = "JetBrainsMono Nerd Font" }
```
3. Restart Alacritty

** GNOME Terminal:**
1. Open Terminal → Preferences → Profiles
2. Select your profile → Click Edit
3. Go to "Text" tab → Click "Change" next to Font
4. Select "JetBrainsMono Nerd Font"
5. Click Select and close

**Note:** You may need to restart your terminal or log out/in for the font to appear in the list.
