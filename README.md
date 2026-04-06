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
