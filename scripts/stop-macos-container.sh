#!/bin/bash

# macOS Container Stop Script
# This script stops a dockur/macos container

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load common utilities
source "$SCRIPT_DIR/common/utils.sh"

# Initialize common configuration
init_common

# Collect final artifacts function
collect_artifacts() {
    log "Collecting final artifacts..."

    local artifacts_dir="$PROJECT_DIR/test-artifacts/${TEST_ID:-$DEFAULT_TEST_ID}"

    if [[ -d "$artifacts_dir" ]]; then
        # Generate test summary
        generate_test_summary "${TEST_ID:-$DEFAULT_TEST_ID}" "completed" "$artifacts_dir"
        success "Test summary created in artifacts directory"
    else
        warning "No artifacts directory found"
    fi
}

# Cleanup resources function
cleanup_resources() {
    log "Cleaning up resources..."

    # Clean up Docker network
    cleanup_docker_network

    # Clean up unused Docker resources
    log "Cleaning up unused Docker resources..."
    docker system prune -f > /dev/null 2>&1 || true
    success "Docker cleanup completed"
}

# Main execution function
main() {
    local force_cleanup=false
    local keep_artifacts=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                force_cleanup=true
                shift
                ;;
            --keep-artifacts)
                keep_artifacts=true
                shift
                ;;
            --test-id)
                export TEST_ID="$2"
                export CONTAINER_NAME="macos-test-$TEST_ID"
                export ARTIFACTS_DIR="$PROJECT_DIR/test-artifacts/$TEST_ID"
                shift 2
                ;;
            -h|--help)
                cat << 'EOF'
macOS Container Stop Script

This script stops and removes a dockur/macos container.

USAGE:
    ./stop-macos-container.sh [OPTIONS]

OPTIONS:
    --force             Force cleanup of all resources
    --keep-artifacts    Keep test artifacts (default: false)
    --test-id TEST_ID   Specific test ID to stop
    -h, --help          Show this help message

EXAMPLES:
    # Stop container with default test ID
    ./stop-macos-container.sh

    # Stop container with specific test ID
    ./stop-macos-container.sh --test-id my-test-001

    # Force cleanup of all resources
    ./stop-macos-container.sh --force

    # Stop container but keep artifacts
    ./stop-macos-container.sh --keep-artifacts
EOF
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    log "Stopping macOS container..."

    # Check dependencies
    check_dependencies

    # Stop container
    stop_container "$CONTAINER_NAME" "$force_cleanup"

    # Collect artifacts if not keeping them
    if ! $keep_artifacts; then
        collect_artifacts
    fi

    # Force cleanup if requested
    if $force_cleanup; then
        cleanup_resources
    fi

    success "macOS container stopped successfully!"
}

# Run main function with all arguments
main "$@"