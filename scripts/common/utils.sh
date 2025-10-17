#!/bin/bash

# Common utility functions for macOS testing scripts
# This library provides shared functionality to reduce code duplication

set -euo pipefail

# =============================================================================
# COLOR AND OUTPUT UTILITIES
# =============================================================================

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Logging functions
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

info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# =============================================================================
# CONFIGURATION UTILITIES
# =============================================================================

# Initialize common configuration variables
init_config() {
    local script_name="${1:-$(basename "$0")}"

    # Directory configuration
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

    # Test configuration
    DEFAULT_TEST_ID="$(date +%Y%m%d_%H%M%S)"
    TEST_ID="${TEST_ID:-$DEFAULT_TEST_ID}"

    # Container configuration
    DEFAULT_CONTAINER_NAME="macos-test-${TEST_ID}"
    CONTAINER_NAME="${CONTAINER_NAME:-$DEFAULT_CONTAINER_NAME}"

    # Port configuration with defaults
    WEB_PORT="${WEB_PORT:-8006}"
    VNC_PORT="${VNC_PORT:-5900}"
    SSH_PORT="${SSH_PORT:-2222}"

    # Directory configuration
    DEFAULT_ARTIFACTS_DIR="$PROJECT_DIR/test-artifacts/$TEST_ID"
    ARTIFACTS_DIR="${ARTIFACTS_DIR:-$DEFAULT_ARTIFACTS_DIR}"

    # Debug mode
    DEBUG="${DEBUG:-false}"

    # Export variables for child processes
    export SCRIPT_DIR PROJECT_DIR TEST_ID CONTAINER_NAME
    export WEB_PORT VNC_PORT SSH_PORT ARTIFACTS_DIR DEBUG
}

# Load environment variables from .env.test file
load_environment() {
    local env_file="$PROJECT_DIR/.env.test"

    if [[ -f "$env_file" ]]; then
        log "Loading environment variables from $env_file"
        set -a
        # shellcheck source=/dev/null
        source "$env_file"
        set +a
    fi
}

# Create test artifacts directory structure
create_artifacts_dir() {
    local test_id="${1:-$TEST_ID}"
    local base_dir="$PROJECT_DIR/test-artifacts/$test_id"

    mkdir -p "$base_dir"/{screenshots,logs,videos,reports}
    echo "$base_dir"
}

# =============================================================================
# DEPENDENCY CHECKING UTILITIES
# =============================================================================

# Check if Docker is available and running
check_docker() {
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed or not in PATH"
        return 1
    fi

    if ! docker info &> /dev/null; then
        error "Docker daemon is not running"
        return 1
    fi

    return 0
}

# Check docker-compose availability
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        error "docker-compose is not installed"
        return 1
    fi
    return 0
}

# Check KVM support (Linux only)
check_kvm() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ ! -e /dev/kvm ]]; then
            warning "KVM device not found. Container performance may be limited."
            warning "Consider enabling KVM virtualization in BIOS/UEFI."
        else
            log "KVM support detected"
        fi
    fi
}

# Comprehensive dependency check
check_dependencies() {
    log "Checking dependencies..."

    local failed=false

    if ! check_docker; then
        failed=true
    fi

    # Additional checks can be added here by specific scripts
    while [[ $# -gt 0 ]]; do
        case $1 in
            docker-compose)
                if ! check_docker_compose; then
                    failed=true
                fi
                ;;
            kvm)
                check_kvm
                ;;
            curl)
                if ! command -v curl &> /dev/null; then
                    error "curl is not installed"
                    failed=true
                fi
                ;;
            nc)
                if ! command -v nc &> /dev/null; then
                    warning "netcat is not installed. Network checks will be limited."
                fi
                ;;
            *)
                warning "Unknown dependency: $1"
                ;;
        esac
        shift
    done

    if $failed; then
        error "Dependency check failed"
        return 1
    fi

    success "All dependencies check passed"
    return 0
}

# =============================================================================
# DOCKER COMPOSE UTILITIES
# =============================================================================

# Get appropriate docker-compose command
get_docker_compose_cmd() {
    if command -v docker-compose &> /dev/null; then
        echo "docker-compose"
    else
        echo "docker compose"
    fi
}

# Create Docker network if it doesn't exist
ensure_docker_network() {
    local network_name="${1:-macos-test-net}"

    if ! docker network ls | grep -q "$network_name"; then
        log "Creating Docker network: $network_name"
        docker network create "$network_name"
    else
        log "Docker network $network_name already exists"
    fi
}

# =============================================================================
# CONTAINER MANAGEMENT UTILITIES
# =============================================================================

# Generate container name based on test ID
get_container_name() {
    local test_id="${1:-$TEST_ID}"
    echo "macos-test-$test_id"
}

# Check if container exists
container_exists() {
    local container_name="${1:-$CONTAINER_NAME}"
    docker ps -a | grep -q "$container_name"
}

# Check if container is running
container_running() {
    local container_name="${1:-$CONTAINER_NAME}"
    docker ps | grep -q "$container_name"
}

# Wait for container to be ready with timeout
wait_for_container() {
    local container_name="${1:-$CONTAINER_NAME}"
    local max_wait="${2:-1800}"  # 30 minutes default
    local wait_interval="${3:-30}"
    local elapsed=0

    log "Waiting for container $container_name to be ready..."

    while [[ $elapsed -lt $max_wait ]]; do
        if container_running "$container_name"; then
            log "Container is running..."

            # Check if web interface is accessible
            if curl -s --max-time 10 "http://localhost:$WEB_PORT" > /dev/null 2>&1; then
                success "Container is ready!"
                return 0
            fi
        fi

        log "Waiting for container to be ready... ($elapsed/$max_wait seconds)"
        sleep $wait_interval
        elapsed=$((elapsed + wait_interval))
    done

    error "Container failed to become ready within $max_wait seconds"
    return 1
}

# =============================================================================
# NETWORK UTILITIES
# =============================================================================

# Check if port is accessible
check_port() {
    local host="${1:-localhost}"
    local port="$2"
    local timeout="${3:-5}"

    if command -v nc &> /dev/null; then
        nc -z "$host" "$port" 2>/dev/null
    elif command -v telnet &> /dev/null; then
        timeout "$timeout" telnet "$host" "$port" </dev/null >/dev/null 2>&1
    else
        # Fallback to curl for HTTP ports
        curl -s --max-time "$timeout" "http://$host:$port" > /dev/null 2>&1
    fi
}

# Show network connectivity status
show_network_status() {
    local test_id="${1:-$TEST_ID}"

    echo ""
    echo "Network Status:"
    echo "=============="

    # Check web interface
    if check_port localhost "$WEB_PORT"; then
        success "Web Interface: http://localhost:$WEB_PORT ✓"
    else
        error "Web Interface: http://localhost:$WEB_PORT ✗"
    fi

    # Check VNC port
    if check_port localhost "$VNC_PORT"; then
        success "VNC: localhost:$VNC_PORT ✓"
    else
        error "VNC: localhost:$VNC_PORT ✗"
    fi

    # Check SSH port
    if check_port localhost "$SSH_PORT"; then
        success "SSH: localhost:$SSH_PORT ✓"
    else
        error "SSH: localhost:$SSH_PORT ✗"
    fi
}

# =============================================================================
# ARTIFACT MANAGEMENT UTILITIES
# =============================================================================

# Generate test summary
generate_test_summary() {
    local test_id="${1:-$TEST_ID}"
    local status="${2:-completed}"
    local artifacts_dir="${3:-$ARTIFACTS_DIR}"
    local summary_file="$artifacts_dir/test-summary.txt"

    mkdir -p "$artifacts_dir"

    cat > "$summary_file" << EOF
macOS Test Summary
==================
Test ID: $test_id
Container: $(get_container_name "$test_id")
End Time: $(date)
Status: $status

Artifacts Collected:
EOF

    # List all artifacts
    if [[ -d "$artifacts_dir" ]]; then
        find "$artifacts_dir" -type f -not -name "test-summary.txt" | while read -r file; do
            echo "- $(basename "$file")" >> "$summary_file"
        done
    fi

    echo "Test summary created: $summary_file"
}

# =============================================================================
# CLEANUP UTILITIES
# =============================================================================

# Clean up Docker network if no containers are using it
cleanup_docker_network() {
    local network_name="${1:-macos-test-net}"

    local network_containers
    network_containers=$(docker network inspect "$network_name" -f '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "")

    if [[ -z "$network_containers" ]]; then
        log "Removing Docker network: $network_name"
        docker network rm "$network_name" 2>/dev/null || true
        success "Docker network removed"
    else
        log "Docker network still in use by: $network_containers"
    fi
}

# Stop and remove container
stop_container() {
    local container_name="${1:-$CONTAINER_NAME}"
    local force="${2:-false}"

    if ! container_exists "$container_name"; then
        warning "Container $container_name does not exist"
        return 0
    fi

    if container_running "$container_name"; then
        log "Stopping container: $container_name"

        if docker stop "$container_name" 2>/dev/null; then
            success "Container stopped"
        elif $force; then
            warning "Failed to stop container gracefully, forcing stop..."
            docker kill "$container_name" || true
        else
            error "Failed to stop container"
            return 1
        fi
    else
        log "Container is already stopped"
    fi

    # Remove container
    log "Removing container..."
    if docker rm "$container_name"; then
        success "Container removed successfully"
    else
        error "Failed to remove container"
        return 1
    fi
}

# =============================================================================
# ARGUMENT PARSING UTILITIES
# =============================================================================

# Parse common arguments
parse_common_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --test-id)
                export TEST_ID="$2"
                export CONTAINER_NAME="macos-test-$TEST_ID"
                export ARTIFACTS_DIR="$PROJECT_DIR/test-artifacts/$TEST_ID"
                shift 2
                ;;
            --debug)
                export DEBUG=true
                shift
                ;;
            -h|--help)
                show_help "${2:-}"
                exit 0
                ;;
            *)
                # Return unknown arguments to caller
                echo "$1"
                shift
                ;;
        esac
    done
}

# Show container information
show_container_info() {
    local container_name="${1:-$CONTAINER_NAME}"
    local test_id="${2:-$TEST_ID}"

    echo ""
    echo "Container Information:"
    echo "====================="
    echo "  Name: $container_name"
    echo "  Test ID: $test_id"
    echo "  Web Interface: http://localhost:$WEB_PORT"
    echo "  VNC: localhost:$VNC_PORT"
    echo "  SSH: ssh root@localhost -p $SSH_PORT"
    echo "  Test Artifacts: $PROJECT_DIR/test-artifacts/$test_id"
    echo ""
}

# =============================================================================
# ERROR HANDLING UTILITIES
# =============================================================================

# Handle script interruption
handle_interrupt() {
    local message="${1:-Script interrupted}"
    error "$message"
    exit 1
}

# Set up interrupt handler
setup_interrupt_handler() {
    trap 'handle_interrupt' INT TERM
}

# =============================================================================
# DEBUG UTILITIES
# =============================================================================

# Debug output function
debug_log() {
    if $DEBUG; then
        log "DEBUG: $1"
    fi
}

# Show script configuration for debugging
show_debug_config() {
    if $DEBUG; then
        echo ""
        echo "Debug Configuration:"
        echo "==================="
        echo "SCRIPT_DIR: $SCRIPT_DIR"
        echo "PROJECT_DIR: $PROJECT_DIR"
        echo "TEST_ID: $TEST_ID"
        echo "CONTAINER_NAME: $CONTAINER_NAME"
        echo "WEB_PORT: $WEB_PORT"
        echo "VNC_PORT: $VNC_PORT"
        echo "SSH_PORT: $SSH_PORT"
        echo "ARTIFACTS_DIR: $ARTIFACTS_DIR"
        echo "DEBUG: $DEBUG"
        echo ""
    fi
}

# =============================================================================
# INITIALIZATION
# =============================================================================

# Initialize the common library
init_common() {
    local script_name="${1:-$(basename "${BASH_SOURCE[1]}")}"

    # Initialize configuration
    init_config "$script_name"

    # Load environment variables
    load_environment

    # Set up interrupt handler
    setup_interrupt_handler

    # Show debug configuration if enabled
    show_debug_config
}

# =============================================================================
# HELP SYSTEM
# =============================================================================

# Generic help function - should be overridden by specific scripts
show_help() {
    local script_name="${1:-$(basename "${BASH_SOURCE[1]}")}"

    cat << EOF
Usage: $script_name [OPTIONS]

Common Options:
  --test-id TEST_ID    Specific test ID to use
  --debug             Enable debug mode
  -h, --help          Show this help message

For script-specific options, run the script with --help.
EOF
}

# Export functions if sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    export -f log error success warning info
    export -f init_config load_environment create_artifacts_dir
    export -f check_docker check_docker_compose check_kvm check_dependencies
    export -f get_docker_compose_cmd ensure_docker_network
    export -f get_container_name container_exists container_running wait_for_container
    export -f check_port show_network_status
    export -f generate_test_summary
    export -f cleanup_docker_network stop_container
    export -f parse_common_args show_container_info
    export -f handle_interrupt setup_interrupt_handler
    export -f debug_log show_debug_config
    export -f init_common show_help
fi
