#!/usr/bin/env python3

"""
Molecule plugin for collecting logs and artifacts from macOS tests.
"""

import json
import os
import subprocess
import sys
from datetime import datetime


def collect_logs(sources):
    """Collect logs from various sources."""
    collected_logs = {}

    for source in sources:
        if source["type"] == "container":
            collected_logs[source["name"]] = collect_container_logs(source)
        elif source["type"] == "file":
            collected_logs[source["name"]] = collect_file_logs(source)
        elif source["type"] == "command":
            collected_logs[source["name"]] = collect_command_logs(source)

    return collected_logs


def collect_container_logs(source):
    """Collect logs from Docker container."""
    container_name = source.get("container_name", "macos-test-local")
    lines = source.get("lines", 100)

    try:
        # Get container logs
        result = subprocess.run(
            ["docker", "logs", "--tail", str(lines), container_name], capture_output=True, text=True, timeout=30
        )
        return {
            "stdout": result.stdout,
            "stderr": result.stderr,
            "return_code": result.returncode,
            "timestamp": datetime.datetime.now().isoformat(),
        }
    except subprocess.TimeoutExpired:
        return {"error": "Timeout while collecting logs", "timestamp": datetime.datetime.now().isoformat()}
    except Exception as e:
        return {"error": f"Error collecting logs: {str(e)}", "timestamp": datetime.datetime.now().isoformat()}


def collect_file_logs(source):
    """Collect logs from file."""
    file_path = source.get("path")
    lines = source.get("lines", 100)

    try:
        with open(file_path, "r") as f:
            content = f.read()

        # Get last N lines
        all_lines = content.strip().split("\n")
        recent_lines = all_lines[-lines:] if len(all_lines) > lines else all_lines

        return {
            "content": "\n".join(recent_lines),
            "total_lines": len(all_lines),
            "timestamp": datetime.datetime.now().isoformat(),
        }
    except FileNotFoundError:
        return {"error": f"File not found: {file_path}", "timestamp": datetime.datetime.now().isoformat()}
    except Exception as e:
        return {"error": f"Error reading file: {str(e)}", "timestamp": datetime.datetime.now().isoformat()}


def collect_command_logs(source):
    """Collect logs from command execution."""
    command = source.get("command")
    timeout = source.get("timeout", 30)

    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=timeout)
        return {
            "command": " ".join(command) if isinstance(command, list) else command,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "return_code": result.returncode,
            "timestamp": datetime.datetime.now().isoformat(),
        }
    except subprocess.TimeoutExpired:
        return {
            "command": " ".join(command) if isinstance(command, list) else command,
            "error": f"Command timed out after {timeout} seconds",
            "timestamp": datetime.datetime.now().isoformat(),
        }
    except Exception as e:
        return {
            "command": " ".join(command) if isinstance(command, list) else command,
            "error": f"Error executing command: {str(e)}",
            "timestamp": datetime.datetime.now().isoformat(),
        }


if __name__ == "__main__":
    # Example usage
    if len(sys.argv) > 1 and sys.argv[1] == "--example":
        sources = [
            {"type": "container", "name": "macos_container", "container_name": "macos-test-local", "lines": 50},
            {"type": "file", "name": "molecule_log", "path": "/tmp/molecule.log", "lines": 100},
        ]
        logs = collect_logs(sources)
        print(json.dumps(logs, indent=2))
    else:
        print("Usage: python collect_logs.py --example")
