#!/usr/bin/env python3

"""
macOS Test Log Analysis Script
Advanced analysis of collected test logs with pattern detection and insights.
"""

import argparse
import json
import os
import re
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple


class LogAnalyzer:
    """Advanced log analyzer for macOS test results."""

    def __init__(self, log_dir: str, output_dir: str):
        self.log_dir = Path(log_dir)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

        # Analysis results
        self.issues = []
        self.insights = []
        self.metrics = {}
        self.timeline = []

    def analyze_all_logs(self) -> Dict:
        """Perform comprehensive analysis of all logs."""
        print(f"🔍 Analyzing logs in {self.log_dir}")

        analysis_results = {
            'summary': {},
            'issues': [],
            'insights': [],
            'metrics': {},
            'timeline': [],
            'recommendations': []
        }

        # Analyze different log categories
        self._analyze_container_logs()
        self._analyze_docker_logs()
        self._analyze_molecule_logs()
        self._analyze_tailscale_logs()
        self._analyze_system_logs()

        # Generate overall analysis
        self._generate_summary()
        self._generate_recommendations()

        # Compile results
        analysis_results.update({
            'issues': self.issues,
            'insights': self.insights,
            'metrics': self.metrics,
            'timeline': self.timeline,
            'summary': self.metrics
        })

        # Save analysis results
        self._save_analysis_results(analysis_results)

        return analysis_results

    def _analyze_container_logs(self):
        """Analyze container-specific logs."""
        container_dir = self.log_dir / 'container'
        if not container_dir.exists():
            return

        # Analyze recent container logs
        recent_log = container_dir / 'container-recent.log'
        if recent_log.exists():
            self._analyze_log_file(recent_log, 'container', {
                'startup_patterns': [
                    r'macOS.*boot',
                    r'System.*ready',
                    r'login.*window',
                    r'display.*manager'
                ],
                'error_patterns': [
                    r'kernel.*panic',
                    r'segmentation.*fault',
                    r'panic:',
                    r'fatal.*error',
                    r'core.*dump'
                ],
                'performance_patterns': [
                    r'CPU.*usage',
                    r'memory.*pressure',
                    r'disk.*I/O',
                    r'network.*timeout'
                ]
            })

        # Analyze container inspection data
        inspect_file = container_dir / 'container-inspect.json'
        if inspect_file.exists():
            try:
                with open(inspect_file, 'r') as f:
                    inspect_data = json.load(f)
                    self._analyze_container_inspection(inspect_data)
            except json.JSONDecodeError:
                self._add_issue('container', 'Invalid JSON in container inspection', 'error')

    def _analyze_docker_logs(self):
        """Analyze Docker and Docker Compose logs."""
        docker_dir = self.log_dir / 'docker'
        if not docker_dir.exists():
            return

        compose_log = docker_dir / 'docker-compose.log'
        if compose_log.exists():
            self._analyze_log_file(compose_log, 'docker', {
                'startup_patterns': [
                    r'Creating.*macos',
                    r'Starting.*macos',
                    r'Container.*healthy'
                ],
                'error_patterns': [
                    r'failed.*start',
                    r'port.*already.*allocated',
                    r'network.*error',
                    r'permission.*denied'
                ],
                'warning_patterns': [
                    r'deprecated',
                    r'warning',
                    r'restart.*policy'
                ]
            })

    def _analyze_molecule_logs(self):
        """Analyze Molecule test execution logs."""
        molecule_dir = self.log_dir / 'molecule'
        if not molecule_dir.exists():
            return

        for log_file in molecule_dir.glob('*.log'):
            scenario_name = log_file.stem.replace('-', '_')
            self._analyze_log_file(log_file, f'molecule_{scenario_name}', {
                'success_patterns': [
                    r'PLAY RECAP.*ok=.*changed=.*unreachable=.*failed=0',
                    r'converge.*completed',
                    r'verify.*completed',
                    r'Test.*successful'
                ],
                'failure_patterns': [
                    r'PLAY RECAP.*failed=[1-9]',
                    r'TASK.*failed',
                    r'fatal.*failed',
                    r'FAILED! =>',
                    r'AssertionError'
                ],
                'performance_patterns': [
                    r'elapsed.*time',
                    r'task.*duration',
                    r'playbook.*execution'
                ]
            })

    def _analyze_tailscale_logs(self):
        """Analyze Tailscale-specific logs and status."""
        tailscale_dir = self.log_dir / 'tailscale'
        if not tailscale_dir.exists():
            return

        # Analyze status files
        status_file = tailscale_dir / 'tailscale-status.txt'
        if status_file.exists():
            self._analyze_tailscale_status(status_file)

        # Analyze JSON status
        status_json = tailscale_dir / 'tailscale-status.json'
        if status_json.exists():
            try:
                with open(status_json, 'r') as f:
                    status_data = json.load(f)
                    self._analyze_tailscale_json_status(status_data)
            except json.JSONDecodeError:
                self._add_issue('tailscale', 'Invalid JSON in Tailscale status', 'error')

        # Analyze service logs
        journal_log = tailscale_dir / 'tailscaled-journal.log'
        if journal_log.exists():
            self._analyze_log_file(journal_log, 'tailscale_service', {
                'error_patterns': [
                    r'error',
                    r'failed.*connect',
                    r'authentication.*failed',
                    r'network.*unreachable'
                ],
                'info_patterns': [
                    r'starting.*tailscaled',
                    r'connected.*to.*control',
                    r'route.*added',
                    r'dns.*configured'
                ]
            })

    def _analyze_system_logs(self):
        """Analyze system-level logs and diagnostics."""
        system_dir = self.log_dir / 'system'
        if not system_dir.exists():
            return

        host_info = system_dir / 'host-system-info.txt'
        if host_info.exists():
            self._analyze_system_info(host_info, 'host')

        container_info = system_dir / 'container-system-info.txt'
        if container_info.exists():
            self._analyze_system_info(container_info, 'container')

    def _analyze_log_file(self, log_file: Path, category: str, patterns: Dict[str, List[str]]):
        """Analyze a single log file for patterns."""
        try:
            with open(log_file, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()

            # Count lines and calculate basic metrics
            lines = content.split('\n')
            total_lines = len(lines)
            error_count = 0
            warning_count = 0

            # Apply pattern matching
            for pattern_type, pattern_list in patterns.items():
                for pattern in pattern_list:
                    matches = re.findall(pattern, content, re.IGNORECASE)
                    if matches:
                        if 'error' in pattern_type:
                            error_count += len(matches)
                            self._add_issue(category, f"Pattern '{pattern}' found {len(matches)} times", 'error')
                        elif 'warning' in pattern_type:
                            warning_count += len(matches)
                            self._add_issue(category, f"Pattern '{pattern}' found {len(matches)} times", 'warning')
                        elif 'success' in pattern_type:
                            self._add_insight(category, f"Success pattern '{pattern}' found {len(matches)} times")

            # Extract timestamps for timeline
            timestamps = self._extract_timestamps(content)
            for timestamp in timestamps:
                self._add_timeline_event(category, timestamp, "Log entry")

            # Store metrics
            self.metrics[f'{category}_lines'] = total_lines
            self.metrics[f'{category}_errors'] = error_count
            self.metrics[f'{category}_warnings'] = warning_count

        except Exception as e:
            self._add_issue(category, f"Failed to analyze log file {log_file}: {str(e)}", 'error')

    def _analyze_container_inspection(self, inspect_data: Dict):
        """Analyze Docker container inspection data."""
        if 'State' in inspect_data:
            state = inspect_data['State']

            # Check container health
            if state.get('Status') != 'running':
                self._add_issue('container', f"Container not running: {state.get('Status')}", 'error')

            if state.get('Health', {}).get('Status') not in ['healthy', None]:
                self._add_issue('container', f"Container unhealthy: {state.get('Health', {}).get('Status')}", 'warning')

            # Check restart count
            restart_count = state.get('RestartCount', 0)
            if restart_count > 0:
                self._add_issue('container', f"Container restarted {restart_count} times", 'warning')

        # Check resource usage
        if 'HostConfig' in inspect_data:
            host_config = inspect_data['HostConfig']
            memory_limit = host_config.get('Memory', 0)
            cpu_limit = host_config.get('CpuQuota', 0)

            if memory_limit > 0:
                self.metrics['container_memory_limit'] = memory_limit
            if cpu_limit > 0:
                self.metrics['container_cpu_limit'] = cpu_limit

    def _analyze_tailscale_status(self, status_file: Path):
        """Analyze Tailscale status text file."""
        try:
            with open(status_file, 'r') as f:
                content = f.read()

            # Check connection status
            if 'Logged out' in content:
                self._add_issue('tailscale', 'Tailscale is logged out', 'error')
            elif 'Tailscale is stopped' in content:
                self._add_issue('tailscale', 'Tailscale service is stopped', 'error')
            elif 'Connected to' in content:
                self._add_insight('tailscale', 'Tailscale is connected and running')

            # Extract peer information
            peer_count = len(re.findall(r'\d+\.\d+\.\d+\.\d+', content))
            self.metrics['tailscale_peer_count'] = peer_count

        except Exception as e:
            self._add_issue('tailscale', f"Failed to analyze status file: {str(e)}", 'error')

    def _analyze_tailscale_json_status(self, status_data: Dict):
        """Analyze Tailscale JSON status data."""
        try:
            # Check backend state
            if status_data.get('BackendState') != 'Running':
                self._add_issue('tailscale', f"Tailscale backend state: {status_data.get('BackendState')}", 'error')

            # Check authentication
            if not status_data.get('AuthEnabled', False):
                self._add_issue('tailscale', 'Tailscale authentication not enabled', 'warning')

            # Extract version information
            version = status_data.get('Version', {})
            if version:
                self.metrics['tailscale_version'] = version.get('Long', 'unknown')

            # Count peers
            peers = status_data.get('Peer', {})
            peer_count = len(peers)
            self.metrics['tailscale_peer_count'] = peer_count

            # Check exit node status
            if status_data.get('CurrentTailnet'):
                self._add_insight('tailscale', f"Connected to tailnet: {status_data.get('CurrentTailnet')}")

        except Exception as e:
            self._add_issue('tailscale', f"Failed to analyze JSON status: {str(e)}", 'error')

    def _analyze_system_info(self, info_file: Path, system_type: str):
        """Analyze system information file."""
        try:
            with open(info_file, 'r') as f:
                content = f.read()

            # Extract resource information
            if 'Memory usage:' in content:
                memory_match = re.search(r'Memory usage:\s*(.+)', content)
                if memory_match:
                    self.metrics[f'{system_type}_memory_info'] = memory_match.group(1).strip()

            if 'Disk usage:' in content:
                disk_match = re.search(r'Disk usage:\s*(.+)', content)
                if disk_match:
                    self.metrics[f'{system_type}_disk_info'] = disk_match.group(1).strip()

            # Check for common issues
            if 'No space left' in content:
                self._add_issue(system_type, 'Disk space full or insufficient', 'error')
            elif 'Cannot allocate memory' in content:
                self._add_issue(system_type, 'Memory allocation issues', 'error')

        except Exception as e:
            self._add_issue(system_type, f"Failed to analyze system info: {str(e)}", 'error')

    def _extract_timestamps(self, content: str) -> List[datetime]:
        """Extract timestamps from log content."""
        timestamps = []

        # Common timestamp patterns
        patterns = [
            r'(\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2})',
            r'(\d{2}/\d{2}/\d{4} \d{2}:\d{2}:\d{2})',
            r'(\w{3} \d{2} \d{2}:\d{2}:\d{2})',
        ]

        for pattern in patterns:
            matches = re.findall(pattern, content)
            for match in matches:
                try:
                    # Try to parse timestamp
                    timestamp = datetime.strptime(match, '%Y-%m-%d %H:%M:%S')
                    timestamps.append(timestamp)
                except ValueError:
                    try:
                        timestamp = datetime.strptime(match, '%Y-%m-%dT%H:%M:%S')
                        timestamps.append(timestamp)
                    except ValueError:
                        # Skip unparsable timestamps
                        continue

        return sorted(timestamps)

    def _add_issue(self, category: str, message: str, severity: str):
        """Add an issue to the analysis results."""
        self.issues.append({
            'category': category,
            'message': message,
            'severity': severity,
            'timestamp': datetime.now().isoformat()
        })

    def _add_insight(self, category: str, message: str):
        """Add an insight to the analysis results."""
        self.insights.append({
            'category': category,
            'message': message,
            'timestamp': datetime.now().isoformat()
        })

    def _add_timeline_event(self, category: str, timestamp: datetime, event: str):
        """Add an event to the timeline."""
        self.timeline.append({
            'category': category,
            'timestamp': timestamp.isoformat(),
            'event': event
        })

    def _generate_summary(self):
        """Generate overall analysis summary."""
        total_errors = sum(1 for issue in self.issues if issue['severity'] == 'error')
        total_warnings = sum(1 for issue in self.issues if issue['severity'] == 'warning')

        self.metrics.update({
            'total_issues': len(self.issues),
            'total_errors': total_errors,
            'total_warnings': total_warnings,
            'total_insights': len(self.insights),
            'analysis_timestamp': datetime.now().isoformat()
        })

    def _generate_recommendations(self):
        """Generate recommendations based on analysis."""
        recommendations = []

        # Check for high error counts
        total_errors = self.metrics.get('total_errors', 0)
        if total_errors > 10:
            recommendations.append({
                'priority': 'high',
                'category': 'errors',
                'message': f'High number of errors detected ({total_errors}). Review error patterns and fix underlying issues.',
                'action': 'Investigate error patterns in log analysis'
            })

        # Check for container issues
        container_errors = sum(1 for issue in self.issues if issue['category'] == 'container')
        if container_errors > 0:
            recommendations.append({
                'priority': 'medium',
                'category': 'container',
                'message': f'Container issues detected ({container_errors}). Check container configuration and resources.',
                'action': 'Review container logs and resource allocation'
            })

        # Check for Tailscale issues
        tailscale_errors = sum(1 for issue in self.issues if issue['category'] == 'tailscale')
        if tailscale_errors > 0:
            recommendations.append({
                'priority': 'medium',
                'category': 'tailscale',
                'message': f'Tailscale issues detected ({tailscale_errors}). Verify authentication and network configuration.',
                'action': 'Check Tailscale status and configuration'
            })

        # Check for test failures
        molecule_errors = sum(1 for issue in self.issues if 'molecule' in issue['category'])
        if molecule_errors > 0:
            recommendations.append({
                'priority': 'high',
                'category': 'testing',
                'message': f'Test failures detected ({molecule_errors}). Review test configuration and role implementation.',
                'action': 'Debug Molecule test failures'
            })

        self.metrics['recommendations'] = recommendations

    def _save_analysis_results(self, results: Dict):
        """Save analysis results to files."""
        # Save JSON results
        json_file = self.output_dir / 'analysis-results.json'
        with open(json_file, 'w') as f:
            json.dump(results, f, indent=2, default=str)

        # Save markdown report
        self._generate_markdown_report(results)

        # Save summary text
        self._generate_text_summary(results)

    def _generate_markdown_report(self, results: Dict):
        """Generate a markdown analysis report."""
        md_file = self.output_dir / 'analysis-report.md'

        with open(md_file, 'w') as f:
            f.write("# macOS Test Log Analysis Report\n\n")
            f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")

            # Executive Summary
            f.write("## Executive Summary\n\n")
            metrics = results.get('metrics', {})
            f.write(f"- **Total Issues**: {metrics.get('total_issues', 0)}\n")
            f.write(f"- **Errors**: {metrics.get('total_errors', 0)}\n")
            f.write(f"- **Warnings**: {metrics.get('total_warnings', 0)}\n")
            f.write(f"- **Insights**: {metrics.get('total_insights', 0)}\n\n")

            # Issues
            issues = results.get('issues', [])
            if issues:
                f.write("## Issues Found\n\n")
                for issue in issues:
                    severity_emoji = "🔴" if issue['severity'] == 'error' else "🟡"
                    f.write(f"- {severity_emoji} **{issue['category'].title()}**: {issue['message']}\n")
                f.write("\n")

            # Recommendations
            recommendations = metrics.get('recommendations', [])
            if recommendations:
                f.write("## Recommendations\n\n")
                for rec in recommendations:
                    priority_emoji = "🔴" if rec['priority'] == 'high' else "🟡" if rec['priority'] == 'medium' else "🟢"
                    f.write(f"### {priority_emoji} {rec['category'].title()}\n")
                    f.write(f"{rec['message']}\n")
                    f.write(f"**Action**: {rec['action']}\n\n")

            # Metrics
            f.write("## Detailed Metrics\n\n")
            for key, value in metrics.items():
                if key not in ['recommendations']:
                    f.write(f"- **{key.replace('_', ' ').title()}**: {value}\n")

    def _generate_text_summary(self, results: Dict):
        """Generate a concise text summary."""
        summary_file = self.output_dir / 'analysis-summary.txt'

        with open(summary_file, 'w') as f:
            f.write("=== macOS Test Log Analysis Summary ===\n")
            f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")

            metrics = results.get('metrics', {})
            f.write(f"Total Issues: {metrics.get('total_issues', 0)}\n")
            f.write(f"Errors: {metrics.get('total_errors', 0)}\n")
            f.write(f"Warnings: {metrics.get('total_warnings', 0)}\n")
            f.write(f"Insights: {metrics.get('total_insights', 0)}\n\n")

            # Top issues
            issues = results.get('issues', [])[:5]
            if issues:
                f.write("Top Issues:\n")
                for issue in issues:
                    f.write(f"- [{issue['severity'].upper()}] {issue['category']}: {issue['message']}\n")
                f.write("\n")

            # Key recommendations
            recommendations = metrics.get('recommendations', [])[:3]
            if recommendations:
                f.write("Key Recommendations:\n")
                for rec in recommendations:
                    f.write(f"- {rec['message']}\n")


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description='Analyze macOS test logs')
    parser.add_argument('--log-dir', required=True, help='Directory containing collected logs')
    parser.add_argument('--output-dir', help='Output directory for analysis results')
    parser.add_argument('--format', choices=['json', 'markdown', 'text', 'all'],
                       default='all', help='Output format(s)')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')

    args = parser.parse_args()

    # Set output directory
    output_dir = args.output_dir or str(Path(args.log_dir).parent / 'analysis')

    # Run analysis
    analyzer = LogAnalyzer(args.log_dir, output_dir)
    results = analyzer.analyze_all_logs()

    if args.verbose:
        print(f"\n📊 Analysis Results:")
        print(f"  Total Issues: {results['metrics']['total_issues']}")
        print(f"  Errors: {results['metrics']['total_errors']}")
        print(f"  Warnings: {results['metrics']['total_warnings']}")
        print(f"  Insights: {results['metrics']['total_insights']}")
        print(f"  Output: {output_dir}")


if __name__ == '__main__':
    main()