#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

detect_os() {
    if [[ -f /proc/version ]] && grep -qE "Microsoft|WSL" /proc/version 2>/dev/null; then
        echo "wsl"
    elif [[ "$(uname)" == "Darwin" ]]; then
        echo "macos"
    elif [[ "$(uname)" == "Linux" ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

install_docker_linux() {
    log_info "Installing Docker..."

    if command -v docker &> /dev/null; then
        log_warn "Docker already installed: $(docker --version)"
        return 0
    fi

    log_info "Installing Docker Engine via convenience script..."
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sudo sh /tmp/get-docker.sh
    rm /tmp/get-docker.sh

    log_info "Adding user to docker group..."
    sudo usermod -aG docker "$USER"

    log_info "Docker installed. You may need to log out and back in for group changes to take effect."
}

install_docker_wsl() {
    log_info "Setting up Docker for WSL2..."

    if command -v docker &> /dev/null; then
        log_warn "Docker already installed: $(docker --version)"
        return 0
    fi

    log_warn "Docker Desktop for Windows is required."
    log_info "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop/"
    log_info "After installation, enable WSL2 integration in Docker Desktop settings."
    log_info "In Docker Desktop > Settings > Resources > WSL Integration, enable your WSL distro."
}

install_devpod() {
    log_info "Installing DevPod..."

    if command -v devpod &> /dev/null; then
        log_warn "DevPod already installed: $(devpod --version)"
        return 0
    fi

    local os
    local arch
    os=$(detect_os)
    arch=$(uname -m)

    case "$arch" in
        x86_64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
    esac

    local version="0.5.17"
    local tmpfile
    tmpfile=$(mktemp)

    case "$os" in
        wsl|linux)
            curl -fsSL "https://github.com/loft-sh/devpod/releases/download/v${version}/devpod-${version}-linux-${arch}.tar.gz" -o "$tmpfile"
            tar -xzf "$tmpfile" -C /tmp
            sudo mv /tmp/devpod-${version}-linux-${arch}/devpod /usr/local/bin/devpod
            rm -rf /tmp/devpod-*
            ;;
        macos)
            if command -v brew &> /dev/null; then
                brew install devpod
            else
                curl -fsSL "https://github.com/loft-sh/devpod/releases/download/v${version}/devpod-${version}-darwin-${arch}.tar.gz" -o "$tmpfile"
                tar -xzf "$tmpfile" -C /tmp
                sudo mv /tmp/devpod-${version}-darwin-${arch}/devpod /usr/local/bin/devpod
                rm -rf /tmp/devpod-*
            fi
            ;;
    esac

    log_info "DevPod installed: $(devpod --version)"
}

check_ssh_keys() {
    local ssh_dir="$HOME/.ssh"
    local key_files=("$ssh_dir/id_ed25519" "$ssh_dir/id_rsa")

    if [[ ! -d "$ssh_dir" ]]; then
        return 1
    fi

    for key in "${key_files[@]}"; do
        if [[ -f "$key" && -f "${key}.pub" ]]; then
            return 0
        fi
    done

    return 1
}

configure_ssh_keys() {
    log_info "Configuring SSH keys for GitHub..."

    if check_ssh_keys; then
        log_warn "SSH keys already exist."
        read -p "Do you want to generate new SSH keys? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping SSH key generation."
            return 0
        fi
    fi

    local email
    read -p "Enter your GitHub email: " email

    if [[ -z "$email" ]]; then
        log_error "Email cannot be empty."
        return 1
    fi

    log_info "Generating ED25519 SSH key..."
    ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519"

    log_info "Adding SSH key to ssh-agent..."
    eval "$(ssh-agent -s)"
    ssh-add "$HOME/.ssh/id_ed25519"

    log_info "Your public key is:"
    echo
    cat "$HOME/.ssh/id_ed25519.pub"
    echo
    log_warn "Add the above key to GitHub: https://github.com/settings/keys"
    log_warn "1. Click 'New SSH key'"
    log_warn "2. Give it a title (e.g., 'WSL Dev Machine')"
    log_warn "3. Paste the public key above"
    log_warn "4. Click 'Add SSH key'"

    read -p "Press Enter after adding the key to GitHub..."

    log_info "Testing SSH connection to GitHub..."
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        log_info "SSH key configured successfully!"
    else
        log_warn "Could not verify SSH connection. Trying to continue..."
    fi
}

verify_installation() {
    log_info "Verifying installation..."

    local missing=0

    if ! command -v docker &> /dev/null; then
        log_error "Docker not found"
        missing=1
    else
        log_info "Docker: $(docker --version)"
    fi

    if ! command -v devpod &> /dev/null; then
        log_error "DevPod not found"
        missing=1
    else
        log_info "DevPod: $(devpod --version)"
    fi

    if ! command -v git &> /dev/null; then
        log_error "Git not found"
        missing=1
    else
        log_info "Git: $(git --version)"
    fi

    if [[ $missing -eq 1 ]]; then
        log_error "Some dependencies are missing. Please check the errors above."
        return 1
    fi

    log_info "All dependencies installed successfully!"
    return 0
}

main() {
    local os
    os=$(detect_os)

    log_info "Detected OS: $os"
    echo

    case "$os" in
        wsl)
            install_docker_wsl
            ;;
        linux)
            install_docker_linux
            ;;
        macos)
            log_info "macOS detected - using Homebrew for Docker"
            if command -v brew &> /dev/null; then
                brew install --cask docker
            else
                log_error "Homebrew not found. Please install Docker Desktop manually."
                return 1
            fi
            ;;
        *)
            log_error "Unsupported operating system"
            return 1
            ;;
    esac

    echo
    install_devpod

    echo
    read -p "Do you want to configure SSH keys for GitHub? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        configure_ssh_keys
    fi

    echo
    verify_installation
}

main "$@"
