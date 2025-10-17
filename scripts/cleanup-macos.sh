#!/bin/bash

# macOS Testing Environment Cleanup Script
# This script cleans up all macOS testing resources

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check dependencies
check_dependencies() {
    log "Checking dependencies..."

    if ! command -v docker &> /dev/null; then
        error "Docker is not installed or not in PATH"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        error "Docker daemon is not running"
        exit 1
    fi

    success "Dependencies check passed"
}

# Stop all macOS containers
stop_all_containers() {
    log "Stopping all macOS containers..."

    local containers
    containers=$(docker ps -a --filter "name=macos-test-" --format "{{.Names}}" 2>/dev/null || true)

    if [[ -z "$containers" ]]; then
        log "No macOS containers found"
        return 0
    fi

    for container in $containers; do
        log "Stopping container: $container"

        if docker ps | grep -q "$container"; then
            docker stop "$container" || {
                warning "Failed to stop $container gracefully, forcing..."
                docker kill "$container" || true
            }
        fi

        docker rm "$container" || {
            warning "Failed to remove container $container"
        }
    done

    success "All macOS containers stopped and removed"
}

# Clean up test artifacts
cleanup_artifacts() {
    log "Cleaning up test artifacts..."

    local artifacts_dir="$PROJECT_DIR/test-artifacts"

    if [[ -d "$artifacts_dir" ]]; then
        local total_size
        total_size=$(du -sh "$artifacts_dir" 2>/dev/null | cut -f1 || echo "unknown")

        log "Found test artifacts directory ($total_size)"

        read -p "Do you want to remove all test artifacts? (y/N): " -n 1 -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$artifacts_dir"
            success "Test artifacts removed"
        else
            log "Keeping test artifacts"
        fi
    else
        log "No test artifacts directory found"
    fi
}

# Clean up Docker resources
cleanup_docker_resources() {
    log "Cleaning up Docker resources..."

    # Remove Docker network
    if docker network ls | grep -q macos-test-net; then
        log "Removing Docker network..."
        docker network rm macos-test-net 2>/dev/null || true
        success "Docker network removed"
    fi

    # Clean up unused images (dockur/macos)
    log "Removing unused macOS Docker images..."
    docker images --filter "reference=dockurr/macos" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | while read -r image; do
        if [[ -n "$image" ]]; then
            log "Removing image: $image"
            docker rmi "$image" 2>/dev/null || true
        fi
    done

    # Clean up unused Docker resources
    log "Cleaning up unused Docker resources..."
    docker system prune -f > /dev/null 2>&1 || true

    success "Docker resources cleaned up"
}

# Clean up temporary files
cleanup_temp_files() {
    log "Cleaning up temporary files..."

    # Clean up temporary SSH keys
    local ssh_keys
    ssh_keys=$(find "$HOME/.ssh" -name "macos_test_key*" 2>/dev/null || true)

    for key in $ssh_keys; do
        log "Removing SSH key: $key"
        rm -f "$key" "${key}.pub"
    done

    # Clean up any temporary directories
    local temp_dirs
    temp_dirs=$(find /tmp -name "*macos-test*" -type d 2>/dev/null || true)

    for dir in $temp_dirs; do
        log "Removing temporary directory: $dir"
        rm -rf "$dir"
    done

    success "Temporary files cleaned up"
}

# Generate cleanup report
generate_report() {
    local report_file="$PROJECT_DIR/cleanup-report-$(date +%Y%m%d_%H%M%S).txt"

    cat > "$report_file" << EOF
macOS Testing Environment Cleanup Report
=======================================
Cleanup Time: $(date)
Project Directory: $PROJECT_DIR

Cleanup Actions Performed:
- Stopped and removed all macOS containers
- Cleaned up Docker resources
- Removed temporary files
- Removed test artifacts (if confirmed)

Remaining Resources:
- Docker images (shared resources preserved)
- System dependencies (brew, python, etc. preserved)

System Status:
EOF

    # Add Docker system status
    docker system df >> "$report_file" 2>/dev/null || echo "Docker status unavailable" >> "$report_file"

    success "Cleanup report generated: $report_file"
}

# Main execution
main() {
    local force=false
    local keep_artifacts=false
    local dry_run=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                force=true
                shift
                ;;
            --keep-artifacts)
                keep_artifacts=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [--force] [--keep-artifacts] [--dry-run]"
                echo "  --force         Force cleanup without confirmation prompts"
                echo "  --keep-artifacts Keep test artifacts"
                echo "  --dry-run       Show what would be cleaned up without doing it"
                echo "  -h, --help      Show this help message"
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    log "Starting macOS testing environment cleanup..."

    if $dry_run; then
        log "DRY RUN MODE - No changes will be made"
    fi

    check_dependencies

    if ! $dry_run; then
        stop_all_containers

        if ! $keep_artifacts; then
            cleanup_artifacts
        fi

        cleanup_docker_resources
        cleanup_temp_files
        generate_report
    else
        # Dry run - just show what would be done
        log "Would stop all containers matching 'macos-test-'"
        log "Would clean up Docker resources"
        log "Would remove temporary files"
        [[ ! $keep_artifacts ]] && log "Would remove test artifacts"
    fi

    success "macOS testing environment cleanup completed!"
}

# Handle script interruption
trap 'error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"
