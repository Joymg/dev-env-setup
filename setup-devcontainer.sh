#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_step() { echo -e "${BLUE}[STEP]${NC} $*"; }

DEFAULT_REPO_URL="git@github.com:Joymg/dev-env-template.git"
DEFAULT_DEV_DIR="$HOME/dev"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Setup a dev container from the template repository.

OPTIONS:
    -r, --repo URL       Repository URL (default: $DEFAULT_REPO_URL)
    -n, --name NAME      Container name (required)
    -d, --dir DIR        Target directory (default: $DEFAULT_DEV_DIR/<name>)
    -u, --user GITHUB_USER GitHub username for dotfiles (default: auto-detect)
    -y, --yes           Skip confirmation prompts
    -h, --help          Show this help message

EXAMPLES:
    $(basename "$0") -n myproject
    $(basename "$0") -n myproject -u mygithubuser
    $(basename "$0") -r git@github.com:user/custom-template.git -n myproject

EOF
}

parse_args() {
    REPO_URL="$DEFAULT_REPO_URL"
    CONTAINER_NAME=""
    TARGET_DIR=""
    GITHUB_USER=""
    SKIP_CONFIRM=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -r|--repo)
                REPO_URL="$2"
                shift 2
                ;;
            -n|--name)
                CONTAINER_NAME="$2"
                shift 2
                ;;
            -d|--dir)
                TARGET_DIR="$2"
                shift 2
                ;;
            -u|--user)
                GITHUB_USER="$2"
                shift 2
                ;;
            -y|--yes)
                SKIP_CONFIRM=1
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    if [[ -z "$CONTAINER_NAME" ]]; then
        log_error "Container name is required. Use -n or --name"
        usage
        exit 1
    fi

    if [[ -z "$TARGET_DIR" ]]; then
        TARGET_DIR="$DEFAULT_DEV_DIR/$CONTAINER_NAME"
    fi
}

detect_github_user() {
    if [[ -n "$GITHUB_USER" ]]; then
        return 0
    fi

    local git_name
    git_name=$(git config --global user.name 2>/dev/null || true)

    if [[ -n "$git_name" ]]; then
        GITHUB_USER=$(echo "$git_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
        log_info "Detected GitHub user: $GITHUB_USER"
    else
        log_warn "Could not detect GitHub user from git config."
        read -p "Enter your GitHub username: " GITHUB_USER
    fi
}

confirm_setup() {
    if [[ $SKIP_CONFIRM -eq 1 ]]; then
        return 0
    fi

    echo
    echo "========================================="
    echo "         SETUP SUMMARY"
    echo "========================================="
    echo "Repository: $REPO_URL"
    echo "Container Name: $CONTAINER_NAME"
    echo "Target Directory: $TARGET_DIR"
    echo "GitHub User: ${GITHUB_USER:-<not set>}"
    echo "========================================="
    echo

    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Aborted."
        exit 0
    fi
}

clone_repo() {
    log_step "Cloning repository..."

    if [[ -d "$TARGET_DIR" ]]; then
        log_warn "Directory already exists: $TARGET_DIR"
        read -p "Remove and re-clone? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$TARGET_DIR"
        else
            log_info "Using existing directory."
            return 0
        fi
    fi

    local parent_dir
    parent_dir=$(dirname "$TARGET_DIR")

    mkdir -p "$parent_dir"

    log_info "Cloning $REPO_URL to $TARGET_DIR..."
    git clone "$REPO_URL" "$TARGET_DIR"

    log_info "Repository cloned successfully."
}

configure_devcontainer() {
    log_step "Configuring dev container..."

    local devcontainer_json="$TARGET_DIR/.devcontainer/devcontainer.json"

    if [[ ! -f "$devcontainer_json" ]]; then
        log_error "devcontainer.json not found in $TARGET_DIR"
        return 1
    fi

    log_info "Updating container name to: $CONTAINER_NAME"

    local tmp_file
    tmp_file=$(mktemp)

    jq --arg name "$CONTAINER_NAME" '.name = $name' "$devcontainer_json" > "$tmp_file"
    mv "$tmp_file" "$devcontainer_json"

    if [[ -n "$GITHUB_USER" ]]; then
        log_info "Setting GitHub user to: $GITHUB_USER"

        tmp_file=$(mktemp)
        jq --arg user "$GITHUB_USER" '.containerEnv.GITHUB_USER = $user' "$devcontainer_json" > "$tmp_file"
        mv "$tmp_file" "$devcontainer_json"
    fi

    log_info "Dev container configured."
}

create_local_override() {
    local override_file="$TARGET_DIR/.devcontainer.json.local"

    if [[ -f "$override_file" ]]; then
        log_warn "Override file already exists: $override_file"
        return 0
    fi

    log_step "Creating local override file..."

    cat > "$override_file" <<EOF
{
  "name": "$CONTAINER_NAME",
  "containerEnv": {
    "GITHUB_USER": "${GITHUB_USER:-}"
  }
}
EOF

    log_info "Created $override_file"
    log_warn "This file is gitignored and will not be committed."
}

build_container() {
    log_step "Building dev container..."

    cd "$TARGET_DIR"

    log_info "Running: devpod up ."
    devpod up .

    log_info "Dev container built successfully!"
    log_info "Connect with: devpod ssh $CONTAINER_NAME"
}

main() {
    parse_args "$@"
    detect_github_user
    confirm_setup
    clone_repo
    configure_devcontainer
    create_local_override
    build_container
}

main "$@"
