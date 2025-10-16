#!/bin/bash

# macOS Test Log Collection Script
# Comprehensive log collection and analysis for macOS Docker tests

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DEFAULT_TEST_ID="local"
CONTAINER_NAME="macos-test-${TEST_ID:-$DEFAULT_TEST_ID}"
DEFAULT_OUTPUT_DIR="$PROJECT_DIR/test-artifacts/${TEST_ID:-$DEFAULT_TEST_ID}"
LOG_DIR="$DEFAULT_OUTPUT_DIR/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Logging function
log() {
    local message="$1"
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $message"
}

error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $message" >&2
}

success() {
    local message="$1"
    echo -e "${GREEN}[SUCCESS]${NC} $message"
}

warning() {
    local message="$1"
    echo -e "${YELLOW}[WARNING]${NC} $message"
}

info() {
    local message="$1"
    echo -e "${CYAN}[INFO]${NC} $message"
}

# Ensure output directory exists
ensure_directories() {
    mkdir -p "$LOG_DIR"/{docker,molecule,container,tailscale,system,analysis}
    mkdir -p "$DEFAULT_OUTPUT_DIR/screenshots"
    log "Created log directories in $LOG_DIR"
}

# Collect Docker and Docker Compose logs
collect_docker_logs() {
    local test_id="${1:-$DEFAULT_TEST_ID}"
    local container_name="${2:-$CONTAINER_NAME}"

    info "Collecting Docker logs..."

    # Docker Compose logs
    if docker-compose -f docker-compose.test.yml ps -q &>/dev/null; then
        docker-compose -f docker-compose.test.yml logs --no-color --timestamps \
            > "$LOG_DIR/docker/docker-compose.log" 2>&1 || true
        log "Docker Compose logs collected"
    fi

    # Individual container logs
    if docker ps --filter "name=$container_name" --quiet | grep -q .; then
        # Recent container logs
        docker logs --tail 1000 --timestamps "$container_name" \
            > "$LOG_DIR/container/container-recent.log" 2>&1 || true

        # Full container logs (might be large)
        docker logs --timestamps "$container_name" \
            > "$LOG_DIR/container/container-full.log" 2>&1 || true

        # Container inspection
        docker inspect "$container_name" \
            > "$LOG_DIR/container/container-inspect.json" 2>&1 || true

        # Container stats snapshot
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" \
            "$container_name" > "$LOG_DIR/container/container-stats.txt" 2>&1 || true

        log "Container logs collected"
    else
        warning "No running container found with name: $container_name"
    fi

    # Docker system info
    docker system df > "$LOG_DIR/docker/system-df.txt" 2>&1 || true
    docker system events --since 1h --format "{{.Time}} {{.Action}} {{.Type}} {{.Actor.Attributes.name}}" \
        > "$LOG_DIR/docker/system-events.txt" 2>&1 || true
}

# Collect Molecule test logs
collect_molecule_logs() {
    info "Collecting Molecule test logs..."

    # Find recent Molecule log files
    find "$PROJECT_DIR" -name "*.log" -path "*/molecule/*" -newer "$PROJECT_DIR" -exec cp {} "$LOG_DIR/molecule/" \; 2>/dev/null || true

    # Collect Molecule state files
    find "$PROJECT_DIR" -name "molecule" -type d -exec find {} -name "*.yml" -o -name "*.json" \; | \
        head -20 | xargs -I {} cp {} "$LOG_DIR/molecule/" 2>/dev/null || true

    # Create Molecule summary
    if ls "$LOG_DIR/molecule"/*.log &>/dev/null; then
        echo "=== Molecule Log Summary ===" > "$LOG_DIR/molecule/molecule-summary.txt"
        echo "Generated: $(date)" >> "$LOG_DIR/molecule/molecule-summary.txt"
        echo "" >> "$LOG_DIR/molecule/molecule-summary.txt"

        for log_file in "$LOG_DIR/molecule"/*.log; do
            if [[ -f "$log_file" ]]; then
                echo "Log file: $(basename "$log_file")" >> "$LOG_DIR/molecule/molecule-summary.txt"
                echo "Size: $(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null || echo "unknown") bytes" >> "$LOG_DIR/molecule/molecule-summary.txt"
                echo "Last modified: $(stat -f%Sm "$log_file" 2>/dev/null || stat -c%y "$log_file" 2>/dev/null || echo "unknown")" >> "$LOG_DIR/molecule/molecule-summary.txt"
                echo "" >> "$LOG_DIR/molecule/molecule-summary.txt"
            fi
        done
    fi

    log "Molecule logs collected"
}

# Collect Tailscale logs from container
collect_tailscale_logs() {
    local container_name="${1:-$CONTAINER_NAME}"

    info "Collecting Tailscale logs..."

    if docker ps --filter "name=$container_name" --quiet | grep -q .; then
        # Try to collect Tailscale logs from inside the container
        docker exec "$container_name" tailscale status --json 2>/dev/null | \
            jq . > "$LOG_DIR/tailscale/tailscale-status.json" 2>/dev/null || true

        docker exec "$container_name" tailscale status 2>/dev/null | \
            tee "$LOG_DIR/tailscale/tailscale-status.txt" >/dev/null || true

        docker exec "$container_name" tailscale version 2>/dev/null | \
            tee "$LOG_DIR/tailscale/tailscale-version.txt" >/dev/null || true

        # Try to collect systemd logs if available
        docker exec "$container_name" journalctl -u tailscaled --no-pager -n 100 2>/dev/null | \
            tee "$LOG_DIR/tailscale/tailscaled-journal.log" >/dev/null || true

        # Try to collect log files
        docker exec "$container_name" find /var/log -name "*tailscale*" 2>/dev/null | \
            head -5 | while read log_path; do
                filename=$(basename "$log_path")
                docker exec "$container_name" cat "$log_path" 2>/dev/null > "$LOG_DIR/tailscale/$filename" || true
            done

        log "Tailscale logs collected"
    else
        warning "Cannot collect Tailscale logs - container not running"
    fi
}

# Collect system logs and diagnostics
collect_system_logs() {
    local container_name="${1:-$CONTAINER_NAME}"

    info "Collecting system logs..."

    # Host system information
    {
        echo "=== Host System Information ==="
        echo "Collected: $(date)"
        echo "Hostname: $(hostname)"
        echo "OS: $(uname -a)"
        echo "Docker version: $(docker --version)"
        echo "Docker Compose version: $(docker-compose --version)"
        echo ""

        echo "=== Docker System Info ==="
        docker system info
        echo ""

        echo "=== Resource Usage ==="
        echo "Memory usage:"
        free -h 2>/dev/null || echo "free command not available"
        echo ""
        echo "Disk usage:"
        df -h | grep -E "(Filesystem|/dev/)"
        echo ""
        echo "Process info:"
        ps aux | grep -E "(docker|macos)" | head -10

    } > "$LOG_DIR/system/host-system-info.txt"

    # Container system information
    if docker ps --filter "name=$container_name" --quiet | grep -q .; then
        {
            echo "=== Container System Information ==="
            echo "Collected: $(date)"
            echo "Container: $container_name"
            echo ""

            echo "=== Container Processes ==="
            docker exec "$container_name" ps aux 2>/dev/null || echo "ps command failed"
            echo ""

            echo "=== Container Network Info ==="
            docker exec "$container_name" ifconfig 2>/dev/null || docker exec "$container_name" ip addr 2>/dev/null || echo "Network info failed"
            echo ""

            echo "=== Container Memory Info ==="
            docker exec "$container_name" vm_stat 2>/dev/null || echo "Memory info failed"
            echo ""

            echo "=== Container Disk Usage ==="
            docker exec "$container_name" df -h 2>/dev/null || echo "Disk info failed"

        } > "$LOG_DIR/system/container-system-info.txt"

        log "System logs collected"
    else
        warning "Cannot collect container system logs - container not running"
    fi
}

# Analyze logs for common issues
analyze_logs() {
    info "Analyzing logs for common issues..."

    {
        echo "=== Log Analysis Report ==="
        echo "Generated: $(date)"
        echo "Test ID: ${TEST_ID:-$DEFAULT_TEST_ID}"
        echo ""

        echo "=== Error Patterns Found ==="
        grep -r -i "error\|failed\|exception\|timeout" "$LOG_DIR" --include="*.log" --include="*.txt" | \
            head -20 || echo "No error patterns found"
        echo ""

        echo "=== Warning Patterns Found ==="
        grep -r -i "warning\|warn\|deprecated" "$LOG_DIR" --include="*.log" --include="*.txt" | \
            head -10 || echo "No warning patterns found"
        echo ""

        echo "=== Tailscale Status Summary ==="
        if [[ -f "$LOG_DIR/tailscale/tailscale-status.txt" ]]; then
            grep -E "(Connected|Disconnected|Healthy)" "$LOG_DIR/tailscale/tailscale-status.txt" || echo "No clear status found"
        else
            echo "No Tailscale status log found"
        fi
        echo ""

        echo "=== Container Health Summary ==="
        if [[ -f "$LOG_DIR/container/container-recent.log" ]]; then
            echo "Recent container log lines: $(wc -l < "$LOG_DIR/container/container-recent.log")"
            grep -c -i "error\|failed" "$LOG_DIR/container/container-recent.log" || echo "0 errors in recent logs"
        else
            echo "No recent container log found"
        fi
        echo ""

        echo "=== Resource Usage Summary ==="
        if [[ -f "$LOG_DIR/container/container-stats.txt" ]]; then
            echo "Container stats available"
        else
            echo "No container stats available"
        fi

    } > "$LOG_DIR/analysis/log-analysis.txt"

    log "Log analysis completed"
}

# Create comprehensive log summary
create_log_summary() {
    local test_id="${1:-$DEFAULT_TEST_ID}"

    info "Creating comprehensive log summary..."

    {
        echo "=== macOS Test Log Collection Summary ==="
        echo "Test ID: $test_id"
        echo "Collection completed: $(date)"
        echo "Collection timestamp: $TIMESTAMP"
        echo ""

        echo "=== Collected Files ==="
        echo "Docker logs: $(find "$LOG_DIR/docker" -type f | wc -l) files"
        echo "Molecule logs: $(find "$LOG_DIR/molecule" -type f | wc -l) files"
        echo "Container logs: $(find "$LOG_DIR/container" -type f | wc -l) files"
        echo "Tailscale logs: $(find "$LOG_DIR/tailscale" -type f | wc -l) files"
        echo "System logs: $(find "$LOG_DIR/system" -type f | wc -l) files"
        echo "Analysis logs: $(find "$LOG_DIR/analysis" -type f | wc -l) files"
        echo ""

        echo "=== Log Directory Structure ==="
        tree "$LOG_DIR" 2>/dev/null || find "$LOG_DIR" -type f | sort
        echo ""

        echo "=== Total Size ==="
        echo "Log directory size: $(du -sh "$LOG_DIR" 2>/dev/null | cut -f1 || echo "unknown")"
        echo ""

        echo "=== Quick Access ==="
        echo "- Main analysis: $LOG_DIR/analysis/log-analysis.txt"
        echo "- Container logs: $LOG_DIR/container/"
        echo "- Tailscale status: $LOG_DIR/tailscale/tailscale-status.txt"
        echo "- System info: $LOG_DIR/system/host-system-info.txt"
        echo "- Molecule logs: $LOG_DIR/molecule/"

    } > "$DEFAULT_OUTPUT_DIR/log-collection-summary.txt"

    success "Log collection summary created: $DEFAULT_OUTPUT_DIR/log-collection-summary.txt"
}

# Archive logs for storage
archive_logs() {
    local archive_name="macos-test-logs-${TEST_ID:-$DEFAULT_TEST_ID}-$TIMESTAMP.tar.gz"
    local archive_path="$DEFAULT_OUTPUT_DIR/../$archive_name"

    info "Archiving logs to $archive_name..."

    if command -v tar >/dev/null 2>&1; then
        tar -czf "$archive_path" -C "$DEFAULT_OUTPUT_DIR" logs 2>/dev/null || true
        success "Logs archived to $archive_path"
    else
        warning "tar command not available, skipping archive creation"
    fi
}

# Main execution
main() {
    local action="collect"
    local test_id="$DEFAULT_TEST_ID"
    local container_name="$CONTAINER_NAME"
    local archive=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --collect)
                action="collect"
                shift
                ;;
            --analyze)
                action="analyze"
                shift
                ;;
            --archive)
                archive=true
                shift
                ;;
            --test-id)
                test_id="$2"
                export TEST_ID="$test_id"
                container_name="macos-test-$test_id"
                shift 2
                ;;
            --container)
                container_name="$2"
                shift 2
                ;;
            --output-dir)
                DEFAULT_OUTPUT_DIR="$2"
                LOG_DIR="$DEFAULT_OUTPUT_DIR/logs"
                shift 2
                ;;
            -h|--help)
                echo "Usage: $0 [--collect] [--analyze] [--archive] [--test-id ID] [--container NAME] [--output-dir DIR]"
                echo "  --collect     Collect all logs (default)"
                echo "  --analyze     Analyze existing logs"
                echo "  --archive     Create archive of logs"
                echo "  --test-id     Test ID to collect logs for"
                echo "  --container   Container name to collect from"
                echo "  --output-dir  Output directory for logs"
                echo "  -h, --help    Show this help message"
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    # Load environment variables
    if [[ -f "$PROJECT_DIR/.env.test" ]]; then
        set -a
        # shellcheck source=/dev/null
        source "$PROJECT_DIR/.env.test"
        set +a
    fi

    # Execute requested action
    case $action in
        collect)
            log "Starting log collection..."
            ensure_directories
            collect_docker_logs "$test_id" "$container_name"
            collect_molecule_logs
            collect_tailscale_logs "$container_name"
            collect_system_logs "$container_name"
            analyze_logs
            create_log_summary "$test_id"

            if [[ "$archive" == "true" ]]; then
                archive_logs
            fi

            success "Log collection completed successfully!"
            info "Logs collected in: $LOG_DIR"
            info "Summary available: $DEFAULT_OUTPUT_DIR/log-collection-summary.txt"
            ;;
        analyze)
            if [[ -d "$LOG_DIR" ]]; then
                analyze_logs
                create_log_summary "$test_id"
                success "Log analysis completed!"
            else
                error "Log directory not found: $LOG_DIR"
                exit 1
            fi
            ;;
    esac
}

# Handle script interruption
trap 'error "Log collection interrupted"; exit 1' INT TERM

# Run main function
main "$@"