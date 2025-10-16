#!/bin/bash

# macOS Container Startup Script
# This script starts a dockur/macos container for testing

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load common utilities
source "$SCRIPT_DIR/common/utils.sh"

# Initialize common configuration
init_common

# Start container function
start_container() {
    log "Starting macOS container..."
    log "Container name: $CONTAINER_NAME"
    log "Test ID: $TEST_ID"

    cd "$PROJECT_DIR"

    # Get docker-compose command
    local docker_cmd
    docker_cmd=$(get_docker_compose_cmd)

    # Start the container
    log "Executing: $docker_cmd -f docker-compose.test.yml up -d"
    if $docker_cmd -f docker-compose.test.yml up -d; then
        success "Container startup initiated"
    else
        error "Failed to start container"
        exit 1
    fi
}

# Setup environment function
setup_environment() {
    log "Setting up environment..."

    # Create test artifacts directory
    create_artifacts_dir

    # Ensure Docker network exists
    ensure_docker_network

    success "Environment setup completed"
}

# Main execution function
main() {
    log "Starting macOS container for testing..."

    # Parse common arguments
    local remaining_args
    remaining_args=$(parse_common_args "$@")

    # Parse script-specific arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --test-id)
                shift 2  # Already handled by parse_common_args
                ;;
            --debug)
                shift  # Already handled by parse_common_args
                ;;
            -h|--help)
                cat << 'EOF'
macOS Container Startup Script

This script starts a dockur/macos container for testing purposes.

USAGE:
    ./start-macos-container.sh [OPTIONS]

OPTIONS:
    --test-id TEST_ID    Specific test ID to use (default: auto-generated)
    --debug             Enable debug mode
    -h, --help          Show this help message

EXAMPLES:
    # Start container with auto-generated test ID
    ./start-macos-container.sh

    # Start container with specific test ID
    ./start-macos-container.sh --test-id my-test-001

    # Start container with debug mode
    ./start-macos-container.sh --debug

ENVIRONMENT VARIABLES:
    WEB_PORT           Web interface port (default: 8006)
    VNC_PORT           VNC port (default: 5900)
    SSH_PORT           SSH port (default: 2222)
    MACOS_VERSION      macOS version to use (default: 14)
    DISK_SIZE          Disk size for container (default: 64G)
    RAM_SIZE           RAM allocation (default: 8G)
    CPU_CORES          Number of CPU cores (default: 4)

OUTPUT:
    Container information and access details will be displayed upon successful startup.
EOF
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    # Check if container already exists
    if container_exists; then
        warning "Container $CONTAINER_NAME already exists"
        read -p "Do you want to remove it and start fresh? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log "Removing existing container..."
            stop_container "$CONTAINER_NAME" true || true
        else
            error "Container already exists. Use a different TEST_ID or remove the existing container."
            exit 1
        fi
    fi

    # Check dependencies
    check_dependencies docker-compose kvm

    # Setup environment
    setup_environment

    # Start container
    start_container

    # Wait for container to be ready
    if wait_for_container; then
        show_container_info
        success "macOS container is ready for testing!"
    else
        error "Failed to start macOS container"
        exit 1
    fi
}

# Run main function with all arguments
main "$@"