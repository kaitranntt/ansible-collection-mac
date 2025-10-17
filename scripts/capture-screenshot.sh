#!/bin/bash

# macOS Container Screenshot Capture Script
# This script captures screenshots from the macOS container for visual monitoring

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load common utilities
source "$SCRIPT_DIR/common/utils.sh"

# Initialize common configuration
init_common

# Screenshot-specific configuration
DEFAULT_OUTPUT_DIR="$PROJECT_DIR/test-artifacts/${TEST_ID:-$DEFAULT_TEST_ID}/screenshots"
DEFAULT_OUTPUT_DIR="${DEFAULT_OUTPUT_DIR:-$ARTIFACTS_DIR/screenshots}"

# Check dependencies for screenshot capture
check_screenshot_dependencies() {
    if ! check_dependencies docker curl; then
        return 1
    fi

    # Check if ImageMagick or ffmpeg is available for image processing
    if ! command -v convert &> /dev/null && ! command -v ffmpeg &> /dev/null; then
        warning "Neither ImageMagick nor ffmpeg found. Screenshots will be saved as-is."
    fi

    return 0
}

# Get container IP address
get_container_ip() {
    local container_name="$1"
    docker inspect "$container_name" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null || echo ""
}

# Capture screenshot via web interface
capture_web_screenshot() {
    local container_name="$1"
    local output_file="$2"
    local web_port="${WEB_PORT:-8006}"
    local max_attempts=3
    local attempt=1

    log "Attempting web-based screenshot capture..."

    while [[ $attempt -le $max_attempts ]]; do
        log "Attempt $attempt of $max_attempts"

        # Try to access the web interface and capture screenshot
        if curl -s --max-time 30 "http://localhost:$web_port" > /dev/null 2>&1; then
            # Use a headless browser or web screenshot API if available
            if command -v chromium-browser &> /dev/null; then
                chromium-browser --headless --disable-gpu --window-size=1024x768 \
                    --screenshot="$output_file" "http://localhost:$web_port" 2>/dev/null || {
                    warning "Chromium screenshot failed"
                }
            elif command -v firefox &> /dev/null; then
                firefox --headless --screenshot="$output_file" \
                    "http://localhost:$web_port" 2>/dev/null || {
                    warning "Firefox screenshot failed"
                }
            else
                # Fallback: Try to capture via VNC or web API
                capture_vnc_screenshot "$container_name" "$output_file"
                return $?
            fi

            # Check if screenshot was created
            if [[ -f "$output_file" && -s "$output_file" ]]; then
                success "Web screenshot captured: $output_file"
                return 0
            fi
        fi

        ((attempt++))
        sleep 5
    done

    warning "Web screenshot capture failed after $max_attempts attempts"
    return 1
}

# Capture screenshot via VNC
capture_vnc_screenshot() {
    local container_name="$1"
    local output_file="$2"
    local vnc_port="${VNC_PORT:-5900}"
    local container_ip
    container_ip=$(get_container_ip "$container_name")

    log "Attempting VNC-based screenshot capture..."

    # Try different VNC screenshot methods
    if command -v vncdo &> /dev/null; then
        # Use vncdo if available
        if vncdo -s "$container_ip:$vnc_port" screenshot "$output_file" 2>/dev/null; then
            success "VNC screenshot captured: $output_file"
            return 0
        fi
    fi

    if command -v import &> /dev/null; then
        # Use ImageMagick import
        if import -window root -display "vnc://$container_ip:$vnc_port" "$output_file" 2>/dev/null; then
            success "VNC screenshot captured: $output_file"
            return 0
        fi
    fi

    # Fallback: Try to execute screenshot command inside container
    if docker exec "$container_name" bash -c "DISPLAY=:0 import -window root /tmp/screenshot.png" 2>/dev/null; then
        docker cp "$container_name:/tmp/screenshot.png" "$output_file" 2>/dev/null && {
            success "Container screenshot captured: $output_file"
            return 0
        }
    fi

    warning "VNC screenshot capture failed"
    return 1
}

# Capture screenshot via direct container access
capture_container_screenshot() {
    local container_name="$1"
    local output_file="$2"

    log "Attempting direct container screenshot capture..."

    # Try to use macOS screencapture command inside container
    if docker exec "$container_name" bash -c "screencapture -x /tmp/screenshot.png" 2>/dev/null; then
        docker cp "$container_name:/tmp/screenshot.png" "$output_file" 2>/dev/null && {
            success "Container screenshot captured: $output_file"
            return 0
        }
    fi

    # Try using xwd (X Window Dump) if available
    if docker exec "$container_name" bash -c "DISPLAY=:0 xwd -root -out /tmp/screenshot.xwd" 2>/dev/null; then
        docker exec "$container_name" bash -c "convert /tmp/screenshot.xwd /tmp/screenshot.png" 2>/dev/null || true
        docker cp "$container_name:/tmp/screenshot.png" "$output_file" 2>/dev/null && {
            success "Container screenshot captured: $output_file"
            return 0
        }
    fi

    warning "Direct container screenshot capture failed"
    return 1
}

# Create a placeholder screenshot
create_placeholder_screenshot() {
    local output_file="$1"
    local reason="$2"

    log "Creating placeholder screenshot: $reason"

    if command -v convert &> /dev/null; then
        convert -size 1024x768 xc:lightgray \
                -pointsize 24 -fill black -gravity center \
                -annotate +0-50 "Screenshot Unavailable" \
                -pointsize 16 -fill darkgray -gravity center \
                -annotate +0-20 "$reason" \
                -pointsize 12 -fill gray -gravity center \
                -annotate +0+20 "$(date)" \
                "$output_file" 2>/dev/null || {
            # Fallback to creating a simple text file
            echo "Screenshot unavailable: $reason" > "$output_file.txt"
            echo "Timestamp: $(date)" >> "$output_file.txt"
        }
    else
        echo "Screenshot unavailable: $reason" > "$output_file.txt"
        echo "Timestamp: $(date)" >> "$output_file.txt"
    fi
}

# Main screenshot capture function
capture_screenshot() {
    local screenshot_name="${1:-screenshot}"
    local output_dir="${2:-$DEFAULT_OUTPUT_DIR}"
    local container_name="${3:-$CONTAINER_NAME}"
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")

    # Create output directory
    mkdir -p "$output_dir"

    local output_file="$output_dir/${screenshot_name}_${timestamp}.png"

    log "Capturing screenshot: $screenshot_name"
    log "Container: $container_name"
    log "Output: $output_file"

    # Check if container is running
    if ! docker ps | grep -q "$container_name"; then
        warning "Container $container_name is not running"
        create_placeholder_screenshot "$output_file" "Container not running"
        return 1
    fi

    # Try different capture methods in order of preference
    if capture_web_screenshot "$container_name" "$output_file"; then
        return 0
    elif capture_container_screenshot "$container_name" "$output_file"; then
        return 0
    else
        create_placeholder_screenshot "$output_file" "All capture methods failed"
        return 1
    fi
}

# Capture multiple screenshots over time
capture_series() {
    local screenshot_name="$1"
    local output_dir="$2"
    local duration="${3:-300}"  # 5 minutes default
    local interval="${4:-30}"    # 30 seconds default
    local container_name="$5"

    local end_time
    end_time=$(($(date +%s) + duration))

    log "Starting screenshot series: $screenshot_name"
    log "Duration: ${duration}s, Interval: ${interval}s"

    while [[ $(date +%s) -lt $end_time ]]; do
        capture_screenshot "$screenshot_name" "$output_dir" "$container_name"
        sleep "$interval"
    done

    success "Screenshot series completed: $screenshot_name"
}

# Generate screenshot report
generate_report() {
    local output_dir="${1:-$DEFAULT_OUTPUT_DIR}"
    local report_file="$output_dir/screenshot-report.txt"

    log "Generating screenshot report..."

    cat > "$report_file" << EOF
Screenshot Capture Report
=======================
Generated: $(date)
Container: $CONTAINER_NAME
Output Directory: $output_dir

Screenshots Captured:
EOF

    if [[ -d "$output_dir" ]]; then
        find "$output_dir" -name "*.png" -type f -exec basename {} \; | sort >> "$report_file" 2>/dev/null || true

        local screenshot_count
        screenshot_count=$(find "$output_dir" -name "*.png" -type f | wc -l)
        local total_size
        total_size=$(du -sh "$output_dir" 2>/dev/null | cut -f1 || echo "unknown")

        echo "" >> "$report_file"
        echo "Total Screenshots: $screenshot_count" >> "$report_file"
        echo "Total Size: $total_size" >> "$report_file"
    else
        echo "No screenshots directory found" >> "$report_file"
    fi

    success "Screenshot report generated: $report_file"
}

# Main execution
main() {
    local screenshot_name="screenshot"
    local output_dir="$DEFAULT_OUTPUT_DIR"
    local container_name="$CONTAINER_NAME"
    local series=false
    local duration=300
    local interval=30
    local generate_report_flag=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --name)
                screenshot_name="$2"
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
            --series)
                series=true
                shift
                ;;
            --duration)
                duration="$2"
                shift 2
                ;;
            --interval)
                interval="$2"
                shift 2
                ;;
            --report)
                generate_report_flag=true
                shift
                ;;
            -h|--help)
                cat << 'EOF'
macOS Container Screenshot Capture Script

This script captures screenshots from the macOS container for visual monitoring.

USAGE:
    ./capture-screenshot.sh [OPTIONS]

OPTIONS:
    --name NAME            Screenshot name prefix (default: screenshot)
    --output-dir DIR       Output directory for screenshots
    --container NAME       Container name to capture from
    --series               Capture a series of screenshots over time
    --duration SECONDS     Duration for series in seconds (default: 300)
    --interval SECONDS     Interval between screenshots in seconds (default: 30)
    --report               Generate screenshot report
    -h, --help             Show this help message

EXAMPLES:
    # Capture single screenshot
    ./capture-screenshot.sh --name before-installation

    # Capture with custom output directory
    ./capture-screenshot.sh --output-dir /tmp/screenshots

    # Capture series over time
    ./capture-screenshot.sh --series --duration 600 --interval 60

    # Generate report after capture
    ./capture-screenshot.sh --report
EOF
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    if ! check_screenshot_dependencies; then
        exit 1
    fi

    if $series; then
        capture_series "$screenshot_name" "$output_dir" "$duration" "$interval" "$container_name"
    else
        capture_screenshot "$screenshot_name" "$output_dir" "$container_name"
    fi

    if $generate_report_flag; then
        generate_report "$output_dir"
    fi
}

# Handle script interruption
trap 'error "Screenshot capture interrupted"; exit 1' INT TERM

# Run main function
main "$@"
