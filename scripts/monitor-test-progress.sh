#!/bin/bash

# macOS Test Progress Monitor
# This script monitors test progress and captures screenshots at key milestones

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DEFAULT_TEST_ID="local"
CONTAINER_NAME="macos-test-${TEST_ID:-$DEFAULT_TEST_ID}"
DEFAULT_OUTPUT_DIR="$PROJECT_DIR/test-artifacts/${TEST_ID:-$DEFAULT_TEST_ID}"
PROGRESS_FILE="$DEFAULT_OUTPUT_DIR/test-progress.json"
LOG_FILE="$DEFAULT_OUTPUT_DIR/monitor.log"

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
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$LOG_FILE"
}

error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $message" >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $message" >> "$LOG_FILE"
}

success() {
    local message="$1"
    echo -e "${GREEN}[SUCCESS]${NC} $message"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $message" >> "$LOG_FILE"
}

warning() {
    local message="$1"
    echo -e "${YELLOW}[WARNING]${NC} $message"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $message" >> "$LOG_FILE"
}

info() {
    local message="$1"
    echo -e "${CYAN}[INFO]${NC} $message"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $message" >> "$LOG_FILE"
}

# Initialize progress tracking
init_progress() {
    local test_id="${1:-$DEFAULT_TEST_ID}"
    local output_dir="${2:-$DEFAULT_OUTPUT_DIR}"

    mkdir -p "$output_dir"

    cat > "$PROGRESS_FILE" << EOF
{
  "test_id": "$test_id",
  "start_time": "$(date -Iseconds)",
  "current_phase": "initialization",
  "phases": {
    "initialization": {
      "status": "in_progress",
      "start_time": "$(date -Iseconds)",
      "description": "Setting up test environment"
    },
    "container_startup": {
      "status": "pending",
      "description": "Starting macOS container"
    },
    "preparation": {
      "status": "pending",
      "description": "Preparing container for testing"
    },
    "installation": {
      "status": "pending",
      "description": "Installing Tailscale"
    },
    "verification": {
      "status": "pending",
      "description": "Verifying installation"
    },
    "cleanup": {
      "status": "pending",
      "description": "Cleaning up resources"
    },
    "completion": {
      "status": "pending",
      "description": "Test completion"
    }
  },
  "milestones": [],
  "screenshots": [],
  "logs": [],
  "last_updated": "$(date -Iseconds)"
}
EOF

    log "Progress tracking initialized for test ID: $test_id"
}

# Update progress phase
update_phase() {
    local phase="$1"
    local status="${2:-in_progress}"
    local message="${3:-}"

    if [[ ! -f "$PROGRESS_FILE" ]]; then
        error "Progress file not found"
        return 1
    fi

    # Create a temporary file with the updated JSON
    local temp_file
    temp_file=$(mktemp)

    # Use jq to update the JSON, or fall back to sed
    if command -v jq &> /dev/null; then
        jq --arg phase "$phase" --arg status "$status" --arg message "$message" '
            .current_phase = $phase |
            .phases[$phase].status = $status |
            .phases[$phase].description = $message |
            if $status == "in_progress" and ($phases[$phase].start_time | not) then
                .phases[$phase].start_time = now
            end |
            if $status == "completed" then
                .phases[$phase].end_time = now
            end |
            .last_updated = now |
            .milestones += [{
                "phase": $phase,
                "status": $status,
                "message": $message,
                "timestamp": now
            }]
        ' "$PROGRESS_FILE" > "$temp_file" && mv "$temp_file" "$PROGRESS_FILE"
    else
        # Fallback to simple text updates (less robust)
        log "Updating phase: $phase -> $status"
        echo "[$(date)] Phase: $phase, Status: $status, Message: $message" >> "$PROGRESS_FILE.txt"
    fi

    log "Phase updated: $phase ($status)"
}

# Add screenshot to progress tracking
add_screenshot() {
    local screenshot_name="$1"
    local screenshot_file="$2"
    local timestamp

    timestamp=$(date -Iseconds)

    if [[ ! -f "$PROGRESS_FILE" ]]; then
        return 1
    fi

    if command -v jq &> /dev/null; then
        local temp_file
        temp_file=$(mktemp)
        jq --arg name "$screenshot_name" --arg file "$screenshot_file" --arg timestamp "$timestamp" '
            .screenshots += [{
                "name": $name,
                "file": $file,
                "timestamp": $timestamp
            }]
            .last_updated = now
        ' "$PROGRESS_FILE" > "$temp_file" && mv "$temp_file" "$PROGRESS_FILE"
    else
        echo "[$timestamp] Screenshot: $screenshot_name -> $screenshot_file" >> "$PROGRESS_FILE.txt"
    fi

    log "Screenshot recorded: $screenshot_name"
}

# Add log entry to progress tracking
add_log() {
    local log_level="$1"
    local log_message="$2"
    local timestamp

    timestamp=$(date -Iseconds)

    if [[ ! -f "$PROGRESS_FILE" ]]; then
        return 1
    fi

    if command -v jq &> /dev/null; then
        local temp_file
        temp_file=$(mktemp)
        jq --arg level "$log_level" --arg message "$log_message" --arg timestamp "$timestamp" '
            .logs += [{
                "level": $level,
                "message": $message,
                "timestamp": $timestamp
            }]
            .last_updated = now
        ' "$PROGRESS_FILE" > "$temp_file" && mv "$temp_file"$ "$PROGRESS_FILE"
    else
        echo "[$timestamp] [$log_level] $log_message" >> "$PROGRESS_FILE.txt"
    fi
}

# Display current progress
show_progress() {
    local output_dir="${1:-$DEFAULT_OUTPUT_DIR}"
    local progress_file="${2:-$PROGRESS_FILE}"

    if [[ ! -f "$progress_file" ]]; then
        error "Progress file not found"
        return 1
    fi

    echo ""
    echo "${MAGENTA}=== Test Progress ===${NC}"

    if command -v jq &> /dev/null; then
        # Display using jq for nice formatting
        jq -r '
            "Test ID: " + .test_id + "\n" +
            "Started: " + .start_time + "\n" +
            "Current Phase: " + .current_phase + "\n" +
            "Status: " + .phases[.current_phase].status + "\n" +
            "Description: " + .phases[.current_phase].description + "\n" +
            "Last Updated: " + .last_updated + "\n" +
            "\n" +
            "=== Phase Status ===\n" +
            ([
                .phases | to_entries[] |
                select(.key != "completion") |
                "\(.key | ascii_upcase): \(.value.status | ascii_upcase) - \(.value.description)\)"
            ] | join("\n")) +
            "\n" +
            "=== Recent Milestones ===\n" +
            ([.milestones[-5:] | .[] |
                "\(.timestamp | strftime("%Y-%m-%d %H:%M:%S")): \(.phase | ascii_upcase) (\(.status | ascii_upcase)) - \(.message)"]
            | join("\n"))
        ' "$progress_file" 2>/dev/null || {
            # Fallback if jq is not available
            echo "Progress file found but jq is not available for formatting"
            tail -20 "$progress_file"
        }
    else
        echo "Progress file found but jq is not available for formatting"
        tail -20 "$progress_file"
    fi
}

# Calculate overall progress percentage
calculate_progress() {
    local progress_file="${1:-$PROGRESS_FILE}"

    if [[ ! -f "$progress_file" ]]; then
        echo "0"
        return 1
    fi

    if command -v jq &> /dev/null; then
        local progress
        progress=$(jq -r '
            # Count completed phases
            (.phases | map_values(select(.status == "completed")) | length) as $completed) /
            # Count total phases (excluding completion)
            ([.phases | keys[] | select(. != "completion")] | length) as $total) |
            if $total > 0 then ($completed / $total * 100) else 0 end
        ' "$progress_file" 2>/dev/null || echo "0")
        echo "${progress%}"
    else
        echo "Unknown"
    fi
}

# Monitor test progress automatically
monitor_progress() {
    local output_dir="${1:-$DEFAULT_OUTPUT_DIR}"
    local interval="${2:-30}"  # Check every 30 seconds
    local duration="${3:-1800}"  # Monitor for 30 minutes
    local container_name="${4:-$CONTAINER_NAME}"

    local end_time
    end_time=$(($(date +%s) + duration))

    log "Starting progress monitoring..."
    log "Container: $container_name"
    log "Duration: ${duration}s, Check interval: ${interval}s"

    while [[ $(date +%s) -lt $end_time ]]; do
        # Check if container is still running
        if ! docker ps | grep -q "$container_name"; then
            warning "Container $container_name is no longer running"
            update_phase "completion" "failed" "Container stopped unexpectedly"
            break
        fi

        # Show current progress
        show_progress "$output_dir"

        # Calculate and display progress percentage
        local progress_percentage
        progress_percentage=$(calculate_progress)
        echo "${CYAN}Progress: $progress_percentage${NC}"

        # Capture a screenshot if enabled
        if [[ "${CAPTURE_SCREENSHOTS:-false}" == "true" ]]; then
            "$SCRIPT_DIR/capture-screenshot.sh" \
                --name "progress-monitor" \
                --output-dir "$output_dir/screenshots" \
                --container "$container_name" \
                2>/dev/null || true
        fi

        # Check if test is complete
        if [[ -f "$output_dir/test-results/installation-complete" ]] || \
           [[ -f "$output_dir/test-results/verification-complete" ]]; then
            success "Test appears to be completed!"
            update_phase "completion" "completed" "All tests completed successfully"
            break
        fi

        echo ""
        echo "Next check in ${interval} seconds... (Press Ctrl+C to stop)"
        echo ""
        sleep "$interval"
    done
}

# Main execution
main() {
    local action="show"
    local test_id="$DEFAULT_TEST_ID"
    local output_dir="$DEFAULT_OUTPUT_DIR"
    local container_name="$CONTAINER_NAME"
    local interval=30
    local duration=1800
    local auto=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --init)
                action="init"
                shift
                ;;
            --update)
                action="update"
                phase="$2"
                status="$3"
                message="${4:-}"
                shift 4
                ;;
            --screenshot)
                action="screenshot"
                screenshot_name="$2"
                screenshot_file="$3"
                shift 3
                ;;
            --log)
                action="log"
                log_level="$2"
                log_message="$3"
                shift 3
                ;;
            --monitor)
                action="monitor"
                auto=true
                shift
                ;;
            --test-id)
                test_id="$2"
                shift 2
                ;;
            --output-dir)
                output_dir="$2"
                shift 2
                ;;
            --container)
                container_name="$2"
                shift 2
                ;;
            --interval)
                interval="$2"
                shift 2
                ;;
            --duration)
                duration="$2"
                shift 2
                ;;
            -h|--help)
                echo "Usage: $0 [--init] [--update PHASE STATUS MESSAGE] [--screenshot NAME FILE] [--log LEVEL MESSAGE] [--monitor] [--test-id ID] [--output-dir DIR] [--container NAME] [--interval SECONDS] [--duration SECONDS]"
                echo "  --init          Initialize progress tracking"
                echo "  --update        Update progress phase"
                echo "  --screenshot    Record a screenshot"
                echo "  --log           Add log entry"
                echo "  --monitor       Monitor progress automatically"
                echo "  --test-id       Test ID to track"
                echo "  --output-dir    Output directory"
                echo "  --container     Container name to monitor"
                echo "  --interval      Check interval in seconds (default: 30)"
                echo "  --duration      Monitor duration in seconds (default: 1800)"
                echo "  -h, --help      Show this help message"
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
        init)
            init_progress "$test_id" "$output_dir"
            ;;
        update)
            update_phase "$phase" "$status" "$message"
            ;;
        screenshot)
            add_screenshot "$screenshot_name" "$screenshot_file"
            ;;
        log)
            add_log "$log_level" "$log_message"
            ;;
        monitor)
            if $auto; then
                monitor_progress "$output_dir" "$interval" "$duration" "$container_name"
            else
                show_progress "$output_dir"
            fi
            ;;
        *)
            show_progress "$output_dir"
            ;;
    esac
}

# Handle script interruption
trap 'error "Progress monitor interrupted"; exit 1' INT TERM

# Run main function
main "$@"
