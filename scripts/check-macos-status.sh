#!/bin/bash

# macOS Container Status Check Script
# This script checks the status of macOS containers and testing environment

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load common utilities
source "$SCRIPT_DIR/common/utils.sh"

# Initialize common configuration
init_common

# Show container status
show_container_status() {
    local test_id="${1:-$TEST_ID}"
    local container_name
    container_name=$(get_container_name "$test_id")

    echo "Container Status:"
    echo "================"

    if docker ps -a --filter "name=$container_name" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q "$container_name"; then
        docker ps -a --filter "name=$container_name" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

        # Get detailed container info
        local container_id
        container_id=$(docker ps -a --filter "name=$container_name" --format "{{.ID}}" | head -1)

        if [[ -n "$container_id" ]]; then
            echo ""
            echo "Container Details:"
            echo "-----------------"
            docker inspect "$container_id" --format "
ID: {{.Id}}
Image: {{.Config.Image}}
Created: {{.Created}}
Network: {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}
Labels: {{range $k, $v := .Config.Labels}}{{$k}}={{$v}} {{end}}
" 2>/dev/null || true
        fi
    else
        warning "No container found with name: $container_name"
    fi
}

# Show all macOS containers
show_all_containers() {
    echo "All macOS Containers:"
    echo "===================="

    local containers
    containers=$(docker ps -a --filter "name=macos-test-" --format "{{.Names}}" 2>/dev/null || true)

    if [[ -z "$containers" ]]; then
        echo "No macOS containers found"
        return 0
    fi

    docker ps -a --filter "name=macos-test-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.CreatedAt}}"
}

# Show resource usage
show_resource_usage() {
    local test_id="${1:-$TEST_ID}"
    local container_name
    container_name=$(get_container_name "$test_id")

    echo ""
    echo "Resource Usage:"
    echo "==============="

    if container_running "$container_name"; then
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}" \
            --filter "name=$container_name" 2>/dev/null || {
            warning "Unable to get resource usage"
        }
    else
        warning "Container is not running"
    fi
}

# Show artifacts
show_artifacts() {
    local test_id="${1:-$TEST_ID}"
    local artifacts_dir="$PROJECT_DIR/test-artifacts/$test_id"

    echo ""
    echo "Test Artifacts:"
    echo "==============="

    if [[ -d "$artifacts_dir" ]]; then
        local total_size
        total_size=$(du -sh "$artifacts_dir" 2>/dev/null | cut -f1 || echo "unknown")

        echo "Directory: $artifacts_dir"
        echo "Total Size: $total_size"
        echo ""

        # Show artifact breakdown
        echo "Artifact Breakdown:"
        for subdir in screenshots logs videos reports; do
            local dir_path="$artifacts_dir/$subdir"
            if [[ -d "$dir_path" ]]; then
                local count
                count=$(find "$dir_path" -type f | wc -l)
                local size
                size=$(du -sh "$dir_path" 2>/dev/null | cut -f1 || echo "0")
                echo "  $subdir: $count files ($size)"
            else
                echo "  $subdir: 0 files"
            fi
        done

        # Show recent files
        echo ""
        echo "Recent Files (last 5):"
        find "$artifacts_dir" -type f -printf "%T@ %p\n" 2>/dev/null | sort -n | tail -5 | while read -r timestamp file; do
            local date_str
            date_str=$(date -d "@${timestamp%.*}" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "unknown")
            local filename
            filename=$(basename "$file")
            echo "  $date_str - $filename"
        done
    else
        warning "No artifacts directory found for test ID: $test_id"
    fi
}

# Show Docker system status
show_docker_status() {
    echo ""
    echo "Docker System Status:"
    echo "===================="

    docker system df
    echo ""

    # Show Docker images related to macOS testing
    echo "macOS Docker Images:"
    docker images --filter "reference=dockurr/macos" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" 2>/dev/null || echo "No macOS images found"

    # Show Docker network
    echo ""
    echo "Docker Networks:"
    if docker network ls | grep -q macos-test-net; then
        docker network ls --filter "name=macos-test-net" --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"
    else
        echo "No macOS test network found"
    fi
}

# Show recent logs
show_recent_logs() {
    local test_id="${1:-$DEFAULT_TEST_ID}"
    local container_name="macos-test-$test_id"

    echo ""
    echo "Recent Logs (last 20 lines):"
    echo "=============================="

    if docker ps | grep -q "$container_name"; then
        docker logs --tail 20 "$container_name" 2>/dev/null || {
            warning "Unable to retrieve logs"
        }
    else
        warning "Container is not running"
    fi
}

# Generate summary
generate_summary() {
    local test_id="${1:-$DEFAULT_TEST_ID}"

    echo ""
    echo "Status Summary:"
    echo "=============="

    local container_name="macos-test-$test_id"
    local container_running=false
    local services_ready=false

    # Check container status
    if docker ps | grep -q "$container_name"; then
        container_running=true
    fi

    # Check services
    if curl -s --max-time 5 "http://localhost:${WEB_PORT:-8006}" > /dev/null 2>&1; then
        services_ready=true
    fi

    # Overall status
    if $container_running && $services_ready; then
        success "OVERALL STATUS: READY"
        info "The macOS testing environment is ready for use."
    elif $container_running && ! $services_ready; then
        warning "OVERALL STATUS: STARTING"
        info "The container is running but services are still starting."
    else
        error "OVERALL STATUS: NOT RUNNING"
        info "The macOS testing environment is not active."
    fi

    echo ""
    echo "Quick Commands:"
    echo "- Start container: ./scripts/start-macos-container.sh"
    echo "- Stop container: ./scripts/stop-macos-container.sh"
    echo "- Clean up: ./scripts/cleanup-macos.sh"
    echo "- Web Interface: http://localhost:${WEB_PORT:-8006}"
}

# Main execution
main() {
    local test_id="$TEST_ID"
    local show_all=false
    local show_logs=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --test-id)
                export TEST_ID="$2"
                export CONTAINER_NAME="macos-test-$TEST_ID"
                export ARTIFACTS_DIR="$PROJECT_DIR/test-artifacts/$TEST_ID"
                test_id="$TEST_ID"
                shift 2
                ;;
            --all)
                show_all=true
                shift
                ;;
            --logs)
                show_logs=true
                shift
                ;;
            -h|--help)
                cat << 'EOF'
macOS Container Status Check Script

This script checks the status of macOS containers and testing environment.

USAGE:
    ./check-macos-status.sh [OPTIONS]

OPTIONS:
    --test-id TEST_ID   Specific test ID to check (default: local)
    --all               Show all macOS containers
    --logs              Show recent container logs
    -h, --help          Show this help message

EXAMPLES:
    # Check status of default container
    ./check-macos-status.sh

    # Check status of specific test ID
    ./check-macos-status.sh --test-id my-test-001

    # Show all containers
    ./check-macos-status.sh --all

    # Show logs as well
    ./check-macos-status.sh --logs
EOF
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    if ! check_dependencies; then
        exit 1
    fi

    if $show_all; then
        show_all_containers
    else
        show_container_status "$test_id"
        show_network_status "$test_id"
        show_resource_usage "$test_id"
        show_artifacts "$test_id"

        if $show_logs; then
            show_recent_logs "$test_id"
        fi
    fi

    show_docker_status
    generate_summary "$test_id"
}

# Run main function
main "$@"