#!/usr/bin/env python3
"""
Quality Metrics Collection and Reporting Script

This script collects various quality metrics from the Ansible collection
and generates comprehensive quality reports including code coverage,
test results, security scores, and maintainability metrics.
"""

import json
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple


class QualityMetricsCollector:
    """Collects and analyzes quality metrics for the Ansible collection."""

    def __init__(self, project_root: str = "."):
        self.project_root = Path(project_root).resolve()
        self.metrics = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "project": {"name": "kaitranntt.mac", "version": "1.0.0", "root": str(self.project_root)},
            "metrics": {},
        }

    def run_command(self, command: List[str], cwd: Optional[str] = None) -> Tuple[int, str, str]:
        """Run a command and return exit code, stdout, and stderr."""
        try:
            result = subprocess.run(command, cwd=cwd or self.project_root, capture_output=True, text=True, timeout=300)
            return result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return 1, "", "Command timed out"
        except Exception as e:
            return 1, "", str(e)

    def collect_code_metrics(self) -> Dict:
        """Collect basic code metrics like line counts and file statistics."""
        print("📊 Collecting code metrics...")

        metrics = {
            "files": {"total": 0, "yaml": 0, "python": 0, "markdown": 0, "json": 0, "other": 0},
            "lines": {"total": 0, "code": 0, "comments": 0, "blank": 0},
            "size": {"total_bytes": 0, "total_kb": 0},
        }

        # Walk through project files
        for root, dirs, files in os.walk(self.project_root):
            # Skip hidden directories and common build/artifact directories
            dirs[:] = [
                d
                for d in dirs
                if not d.startswith(".") and d not in ["__pycache__", "node_modules", ".git", ".tox", ".molecule"]
            ]

            for file in files:
                if file.startswith("."):
                    continue

                file_path = Path(root) / file
                relative_path = file_path.relative_to(self.project_root)

                try:
                    with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                        content = f.read()
                        lines = content.split("\n")

                    metrics["files"]["total"] += 1
                    metrics["size"]["total_bytes"] += file_path.stat().st_size

                    # File type counting
                    if file.endswith((".yml", ".yaml")):
                        metrics["files"]["yaml"] += 1
                    elif file.endswith(".py"):
                        metrics["files"]["python"] += 1
                    elif file.endswith((".md", ".rst")):
                        metrics["files"]["markdown"] += 1
                    elif file.endswith(".json"):
                        metrics["files"]["json"] += 1
                    else:
                        metrics["files"]["other"] += 1

                    # Line counting
                    for line in lines:
                        metrics["lines"]["total"] += 1
                        line_stripped = line.strip()
                        if not line_stripped:
                            metrics["lines"]["blank"] += 1
                        elif line_stripped.startswith("#"):
                            metrics["lines"]["comments"] += 1
                        else:
                            metrics["lines"]["code"] += 1

                except (OSError, UnicodeDecodeError):
                    # Skip files that can't be read
                    continue

        metrics["size"]["total_kb"] = round(metrics["size"]["total_bytes"] / 1024, 2)

        # Calculate percentages
        if metrics["lines"]["total"] > 0:
            metrics["lines"]["code_percentage"] = round((metrics["lines"]["code"] / metrics["lines"]["total"]) * 100, 2)
            metrics["lines"]["comment_percentage"] = round(
                (metrics["lines"]["comments"] / metrics["lines"]["total"]) * 100, 2
            )
            metrics["lines"]["blank_percentage"] = round(
                (metrics["lines"]["blank"] / metrics["lines"]["total"]) * 100, 2
            )
        else:
            metrics["lines"]["code_percentage"] = 0
            metrics["lines"]["comment_percentage"] = 0
            metrics["lines"]["blank_percentage"] = 0

        return metrics

    def collect_test_metrics(self) -> Dict:
        """Collect test execution and coverage metrics."""
        print("🧪 Collecting test metrics...")

        metrics = {
            "ansible_lint": {"status": "not_run", "issues": 0, "errors": 0, "warnings": 0},
            "molecule": {
                "status": "not_run",
                "scenarios_tested": 0,
                "tests_passed": 0,
                "tests_failed": 0,
                "coverage": 0,
            },
            "yamllint": {"status": "not_run", "issues": 0, "errors": 0, "warnings": 0},
        }

        # Run ansible-lint
        returncode, stdout, stderr = self.run_command(["ansible-lint", ".", "--quiet", "--parseable"])
        if returncode == 0:
            metrics["ansible_lint"]["status"] = "passed"
            metrics["ansible_lint"]["issues"] = 0
        else:
            metrics["ansible_lint"]["status"] = "failed"
            # Count issues from output
            metrics["ansible_lint"]["issues"] = len(stdout.strip().split("\n")) if stdout.strip() else 0

        # Run yamllint
        returncode, stdout, stderr = self.run_command(["yamllint", ".", "--format", "parsable"])
        if returncode == 0:
            metrics["yamllint"]["status"] = "passed"
            metrics["yamllint"]["issues"] = 0
        else:
            metrics["yamllint"]["status"] = "failed"
            metrics["yamllint"]["issues"] = len(stdout.strip().split("\n")) if stdout.strip() else 0

        # Check Molecule test results
        molecule_dir = self.project_root / "molecule" / "default"
        if molecule_dir.exists():
            # Look for recent test results
            test_files = list(molecule_dir.glob("**/*.xml")) + list(molecule_dir.glob("**/test-results/*.json"))
            if test_files:
                metrics["molecule"]["status"] = "tested"
                metrics["molecule"]["scenarios_tested"] = len(test_files)
                # Simple assumption - if tests ran, they passed
                metrics["molecule"]["tests_passed"] = len(test_files)
            else:
                metrics["molecule"]["status"] = "configured"
                metrics["molecule"]["scenarios_tested"] = 1

        return metrics

    def collect_security_metrics(self) -> Dict:
        """Collect security scanning metrics."""
        print("🛡️ Collecting security metrics...")

        metrics = {
            "overall_score": 0,
            "scan_status": "not_run",
            "vulnerabilities": {"critical": 0, "high": 0, "medium": 0, "low": 0, "info": 0},
            "tools": {
                "checkov": {"status": "not_run", "issues": 0},
                "bandit": {"status": "not_run", "issues": 0},
                "safety": {"status": "not_run", "issues": 0},
                "secrets": {"status": "not_run", "secrets_found": 0},
            },
        }

        # Look for existing security reports
        security_dir = self.project_root / "security-reports"
        if security_dir.exists():
            metrics["scan_status"] = "reports_available"

            # Checkov report
            checkov_report = security_dir / "checkov-report.json"
            if checkov_report.exists() and checkov_report.is_file():
                try:
                    with open(checkov_report, "r") as f:
                        checkov_data = json.load(f)
                        metrics["tools"]["checkov"]["status"] = "completed"
                        metrics["tools"]["checkov"]["issues"] = len(
                            checkov_data.get("results", {}).get("failed_controls", [])
                        )

                        # Count by severity
                        for result in checkov_data.get("results", {}).get("failed_controls", []):
                            severity = result.get("severity", "unknown").lower()
                            if severity in metrics["vulnerabilities"]:
                                metrics["vulnerabilities"][severity] += 1
                except (json.JSONDecodeError, KeyError):
                    pass

            # Bandit report
            bandit_report = security_dir / "bandit-report.json"
            if bandit_report.exists() and bandit_report.is_file():
                try:
                    with open(bandit_report, "r") as f:
                        bandit_data = json.load(f)
                        metrics["tools"]["bandit"]["status"] = "completed"
                        metrics["tools"]["bandit"]["issues"] = len(bandit_data.get("results", []))

                        # Count by severity (bandit uses different severity levels)
                        for result in bandit_data.get("results", []):
                            issue_severity = result.get("issue_severity", "LOW").upper()
                            if issue_severity in ["HIGH"]:
                                metrics["vulnerabilities"]["high"] += 1
                            elif issue_severity in ["MEDIUM"]:
                                metrics["vulnerabilities"]["medium"] += 1
                            else:
                                metrics["vulnerabilities"]["low"] += 1
                except (json.JSONDecodeError, KeyError):
                    pass

            # Safety report
            safety_report = security_dir / "safety-summary.txt"
            if safety_report.exists() and safety_report.is_file():
                try:
                    with open(safety_report, "r") as f:
                        content = f.read()
                        metrics["tools"]["safety"]["status"] = "completed"
                        # Extract vulnerability count from safety summary
                        if "0 vulnerabilities reported" in content:
                            metrics["tools"]["safety"]["issues"] = 0
                        else:
                            # Try to extract number from text
                            match = re.search(r"(\d+)\s+vulnerabilities?", content)
                            if match:
                                metrics["tools"]["safety"]["issues"] = int(match.group(1))
                                metrics["vulnerabilities"]["medium"] += int(match.group(1))
                except OSError:
                    pass

            # Secrets report
            secrets_report = security_dir / "secret-files.txt"
            if secrets_report.exists() and secrets_report.is_file():
                try:
                    with open(secrets_report, "r") as f:
                        content = f.read()
                        metrics["tools"]["secrets"]["status"] = "completed"
                        # Count non-certificate files (certificates are expected)
                        lines = [line.strip() for line in content.split("\n") if line.strip()]
                        non_cert_lines = [line for line in lines if "certifi" not in line and ".pem" not in line]
                        metrics["tools"]["secrets"]["secrets_found"] = len(non_cert_lines)
                        if len(non_cert_lines) > 0:
                            metrics["vulnerabilities"]["critical"] += len(non_cert_lines)
                except OSError:
                    pass

            # Calculate overall security score (simple scoring algorithm)
            total_score = 100
            if metrics["vulnerabilities"]["critical"] > 0:
                total_score -= 40
            if metrics["vulnerabilities"]["high"] > 0:
                total_score -= 20
            if metrics["vulnerabilities"]["medium"] > 0:
                total_score -= 10
            if metrics["vulnerabilities"]["low"] > 0:
                total_score -= 5

            metrics["overall_score"] = max(0, total_score)

        return metrics

    def collect_documentation_metrics(self) -> Dict:
        """Collect documentation quality metrics."""
        print("📚 Collecting documentation metrics...")

        metrics = {
            "status": "not_analyzed",
            "files": {
                "total": 0,
                "readme": 0,
                "contributing": 0,
                "changelog": 0,
                "license": 0,
                "api_docs": 0,
                "guides": 0,
            },
            "coverage": {
                "score": 0,
                "roles_documented": 0,
                "total_roles": 0,
                "variables_documented": 0,
                "total_variables": 0,
            },
            "quality": {
                "word_count": 0,
                "has_examples": False,
                "has_installation_guide": False,
                "has_usage_guide": False,
            },
        }

        # Count documentation files
        docs_dir = self.project_root / "docs"
        project_files = list(self.project_root.glob("*.md")) + list(self.project_root.glob("*.rst"))

        metrics["files"]["total"] = len(project_files)

        for file_path in project_files:
            if file_path.name.lower().startswith("readme"):
                metrics["files"]["readme"] += 1
            elif "contributing" in file_path.name.lower():
                metrics["files"]["contributing"] += 1
            elif "changelog" in file_path.name.lower() or "change_log" in file_path.name.lower():
                metrics["files"]["changelog"] += 1
            elif "license" in file_path.name.lower():
                metrics["files"]["license"] += 1

        # Count docs directory files
        if docs_dir.exists():
            doc_files = list(docs_dir.rglob("*.md")) + list(docs_dir.rglob("*.rst"))
            metrics["files"]["api_docs"] = len(
                [
                    f
                    for f in doc_files
                    if any(keyword in f.name.lower() for keyword in ["api", "modules", "roles", "plugins"])
                ]
            )
            metrics["files"]["guides"] = len(
                [
                    f
                    for f in doc_files
                    if any(keyword in f.name.lower() for keyword in ["guide", "usage", "installation", "getting"])
                ]
            )

        # Analyze roles documentation
        roles_dir = self.project_root / "roles"
        if roles_dir.exists():
            for role_dir in roles_dir.iterdir():
                if role_dir.is_dir():
                    metrics["coverage"]["total_roles"] += 1
                    # Check if role has README
                    if (role_dir / "README.md").exists() or (role_dir / "README.rst").exists():
                        metrics["coverage"]["roles_documented"] += 1

        # Calculate coverage score
        if metrics["coverage"]["total_roles"] > 0:
            metrics["coverage"]["score"] = round(
                (metrics["coverage"]["roles_documented"] / metrics["coverage"]["total_roles"]) * 100, 2
            )

        # Analyze main README for quality indicators
        readme_file = self.project_root / "README.md"
        if readme_file.exists():
            try:
                with open(readme_file, "r", encoding="utf-8") as f:
                    content = f.read().lower()
                    metrics["quality"]["word_count"] = len(content.split())
                    metrics["quality"]["has_examples"] = "example" in content or "usage" in content
                    metrics["quality"]["has_installation_guide"] = "install" in content
                    metrics["quality"]["has_usage_guide"] = "usage" in content or "how to" in content
            except OSError:
                pass

        metrics["status"] = "analyzed"
        return metrics

    def calculate_overall_quality_score(self) -> Dict:
        """Calculate overall quality score based on all metrics."""
        print("🎯 Calculating overall quality score...")

        score_metrics = {
            "overall_score": 0,
            "grade": "A+",
            "components": {
                "code_quality": {"weight": 25, "score": 0},
                "test_coverage": {"weight": 30, "score": 0},
                "security_posture": {"weight": 25, "score": 0},
                "documentation": {"weight": 20, "score": 0},
            },
            "thresholds": {"A+": 90, "A": 80, "B": 70, "C": 60, "D": 50},
        }

        # Code quality score (based on comment ratio and file organization)
        code_metrics = self.metrics["metrics"].get("code", {})
        if code_metrics.get("lines", {}).get("total", 0) > 0:
            comment_ratio = code_metrics["lines"].get("comment_percentage", 0)
            # Good comment ratio is around 10-20%
            if 10 <= comment_ratio <= 25:
                code_score = 100
            elif comment_ratio >= 5:
                code_score = 80
            else:
                code_score = 60
            score_metrics["components"]["code_quality"]["score"] = code_score

        # Test coverage score
        test_metrics = self.metrics["metrics"].get("tests", {})
        test_score = 100  # Start with perfect score

        if test_metrics.get("ansible_lint", {}).get("status") == "failed":
            test_score -= 20
        if test_metrics.get("yamllint", {}).get("status") == "failed":
            test_score -= 15
        if test_metrics.get("molecule", {}).get("status") == "not_run":
            test_score -= 30
        elif test_metrics.get("molecule", {}).get("status") == "configured":
            test_score -= 10

        score_metrics["components"]["test_coverage"]["score"] = max(0, test_score)

        # Security posture score
        security_metrics = self.metrics["metrics"].get("security", {})
        score_metrics["components"]["security_posture"]["score"] = security_metrics.get("overall_score", 0)

        # Documentation score
        doc_metrics = self.metrics["metrics"].get("documentation", {})
        doc_score = 0

        if doc_metrics.get("files", {}).get("readme", 0) > 0:
            doc_score += 25
        if doc_metrics.get("files", {}).get("contributing", 0) > 0:
            doc_score += 15
        if doc_metrics.get("files", {}).get("license", 0) > 0:
            doc_score += 10
        if doc_metrics.get("coverage", {}).get("score", 0) > 0:
            doc_score += doc_metrics["coverage"]["score"] * 0.3  # Max 30 points

        score_metrics["components"]["documentation"]["score"] = min(100, doc_score)

        # Calculate weighted overall score
        total_weighted_score = 0
        total_weight = 0

        for component, data in score_metrics["components"].items():
            weight = data["weight"]
            score = data["score"]
            total_weighted_score += weight * score
            total_weight += weight

        if total_weight > 0:
            score_metrics["overall_score"] = round(total_weighted_score / total_weight, 1)

        # Determine grade
        overall_score = score_metrics["overall_score"]
        thresholds = score_metrics["thresholds"]

        if overall_score >= thresholds["A+"]:
            score_metrics["grade"] = "A+"
        elif overall_score >= thresholds["A"]:
            score_metrics["grade"] = "A"
        elif overall_score >= thresholds["B"]:
            score_metrics["grade"] = "B"
        elif overall_score >= thresholds["C"]:
            score_metrics["grade"] = "C"
        elif overall_score >= thresholds["D"]:
            score_metrics["grade"] = "D"
        else:
            score_metrics["grade"] = "F"

        return score_metrics

    def generate_report(self) -> Dict:
        """Generate comprehensive quality metrics report."""
        print("📋 Generating quality metrics report...")

        # Collect all metrics
        self.metrics["metrics"]["code"] = self.collect_code_metrics()
        self.metrics["metrics"]["tests"] = self.collect_test_metrics()
        self.metrics["metrics"]["security"] = self.collect_security_metrics()
        self.metrics["metrics"]["documentation"] = self.collect_documentation_metrics()
        self.metrics["metrics"]["overall_score"] = self.calculate_overall_quality_score()

        return self.metrics

    def save_report(self, output_file: str = "quality-reports/quality-metrics.json"):
        """Save metrics report to file."""
        # Create reports directory
        output_path = Path(output_file)
        output_path.parent.mkdir(exist_ok=True)

        with open(output_path, "w") as f:
            json.dump(self.metrics, f, indent=2)

        print(f"✅ Quality metrics report saved to: {output_path}")
        return output_path

    def generate_markdown_report(self, output_file: str = "quality-reports/QUALITY_REPORT.md"):
        """Generate human-readable markdown report."""
        print("📝 Generating markdown quality report...")

        output_path = Path(output_file)
        output_path.parent.mkdir(exist_ok=True)

        # Extract key metrics
        overall = self.metrics["metrics"]["overall_score"]
        code = self.metrics["metrics"]["code"]
        tests = self.metrics["metrics"]["tests"]
        security = self.metrics["metrics"]["security"]
        docs = self.metrics["metrics"]["documentation"]

        report_content = f"""# Quality Metrics Report

**Generated**: {self.metrics['timestamp']}
**Project**: {self.metrics['project']['name']} v{self.metrics['project']['version']}

## Executive Summary

### Overall Quality Grade: {overall['grade']} ({overall['overall_score']}/100)

{self._get_quality_emoji(overall['overall_score'])} The project demonstrates {'excellent' if overall['overall_score'] >= 90 else 'good' if overall['overall_score'] >= 80 else 'acceptable' if overall['overall_score'] >= 70 else 'needs improvement'} quality standards.

### Component Scores

| Component | Score | Weight | Contribution |
|-----------|-------|--------|--------------|
| Code Quality | {overall['components']['code_quality']['score']}/100 | {overall['components']['code_quality']['weight']}% | {round(overall['components']['code_quality']['score'] * overall['components']['code_quality']['weight'] / 100, 1)} |
| Test Coverage | {overall['components']['test_coverage']['score']}/100 | {overall['components']['test_coverage']['weight']}% | {round(overall['components']['test_coverage']['score'] * overall['components']['test_coverage']['weight'] / 100, 1)} |
| Security Posture | {overall['components']['security_posture']['score']}/100 | {overall['components']['security_posture']['weight']}% | {round(overall['components']['security_posture']['score'] * overall['components']['security_posture']['weight'] / 100, 1)} |
| Documentation | {overall['components']['documentation']['score']}/100 | {overall['components']['documentation']['weight']}% | {round(overall['components']['documentation']['score'] * overall['components']['documentation']['weight'] / 100, 1)} |

## Detailed Metrics

### 📊 Code Quality

**Files**: {code['files']['total']} total
- YAML: {code['files']['yaml']}
- Python: {code['files']['python']}
- Markdown: {code['files']['markdown']}
- Other: {code['files']['other']}

**Lines**: {code['lines']['total']} total
- Code: {code['lines']['code']} ({code['lines'].get('code_percentage', 0)}%)
- Comments: {code['lines']['comments']} ({code['lines'].get('comment_percentage', 0)}%)
- Blank: {code['lines']['blank']} ({code['lines'].get('blank_percentage', 0)}%)

**Size**: {code['size']['total_kb']} KB

### 🧪 Test Coverage

| Test Type | Status | Issues |
|------------|--------|--------|
| Ansible Lint | {tests['ansible_lint']['status']} | {tests['ansible_lint']['issues']} |
| YAML Lint | {tests['yamllint']['status']} | {tests['yamllint']['issues']} |
| Molecule | {tests['molecule']['status']} | {tests['molecule'].get('scenarios_tested', 0)} scenarios |

### 🛡️ Security Posture

**Security Score**: {security['overall_score']}/100

**Vulnerabilities**:
- Critical: {security['vulnerabilities']['critical']}
- High: {security['vulnerabilities']['high']}
- Medium: {security['vulnerabilities']['medium']}
- Low: {security['vulnerabilities']['low']}

**Security Tools Status**:
- Checkov: {security['tools']['checkov']['status']} ({security['tools']['checkov']['issues']} issues)
- Bandit: {security['tools']['bandit']['status']} ({security['tools']['bandit']['issues']} issues)
- Safety: {security['tools']['safety']['status']} ({security['tools']['safety']['issues']} issues)
- Secret Scan: {security['tools']['secrets']['status']} ({security['tools']['secrets']['secrets_found']} secrets)

### 📚 Documentation Quality

**Files**: {docs['files']['total']} total
- README: {docs['files']['readme']}
- Contributing: {docs['files']['contributing']}
- Changelog: {docs['files']['changelog']}
- License: {docs['files']['license']}

**Coverage**: {docs['coverage']['score']}% of roles documented
- Roles documented: {docs['coverage']['roles_documented']}/{docs['coverage']['total_roles']}

**Quality Indicators**:
- Word count: {docs['quality']['word_count']}
- Has examples: {'✅' if docs['quality']['has_examples'] else '❌'}
- Has installation guide: {'✅' if docs['quality']['has_installation_guide'] else '❌'}
- Has usage guide: {'✅' if docs['quality']['has_usage_guide'] else '❌'}

## Recommendations

{self._generate_recommendations(overall, tests, security, docs)}

## Next Steps

1. Address any failed tests or linting issues
2. Improve documentation coverage if below 80%
3. Monitor security scan results regularly
4. Set up automated quality reporting in CI/CD

---

*This report was generated automatically using the quality metrics collection script. For questions about these metrics, see the project documentation or contact the maintainers.*
"""

        with open(output_path, "w") as f:
            f.write(report_content)

        print(f"✅ Markdown quality report saved to: {output_path}")
        return output_path

    def _get_quality_emoji(self, score: float) -> str:
        """Get emoji based on quality score."""
        if score >= 90:
            return "🏆"
        elif score >= 80:
            return "✅"
        elif score >= 70:
            return "⚠️"
        else:
            return "❌"

    def _generate_recommendations(self, overall: Dict, tests: Dict, security: Dict, docs: Dict) -> str:
        """Generate recommendations based on metrics."""
        recommendations = []

        # Test recommendations
        if tests["ansible_lint"]["status"] == "failed":
            recommendations.append(
                "1. **Fix Ansible Lint Issues**: Address the {} ansible-lint violations to improve code quality.".format(
                    tests["ansible_lint"]["issues"]
                )
            )

        if tests["yamllint"]["status"] == "failed":
            recommendations.append(
                "2. **Fix YAML Lint Issues**: Resolve the {} yamllint violations for better YAML formatting.".format(
                    tests["yamllint"]["issues"]
                )
            )

        if tests["molecule"]["status"] == "not_run":
            recommendations.append(
                "3. **Set Up Molecule Testing**: Configure and run Molecule tests to ensure role functionality."
            )

        # Security recommendations
        if security["overall_score"] < 90:
            recommendations.append(
                "4. **Improve Security Posture**: Address the identified security vulnerabilities to improve the security score."
            )

        # Documentation recommendations
        if docs["coverage"]["score"] < 80:
            recommendations.append(
                "5. **Enhance Documentation**: Improve documentation coverage by adding README files for all roles."
            )

        if not docs["quality"]["has_examples"]:
            recommendations.append("6. **Add Usage Examples**: Include practical examples in the documentation.")

        if not recommendations:
            recommendations.append(
                "🎉 **Excellent Work**: No immediate improvements needed - continue maintaining current quality standards!"
            )

        return "\n\n".join(recommendations)


def main():
    """Main entry point for the quality metrics script."""
    import argparse

    parser = argparse.ArgumentParser(description="Collect and report quality metrics for Ansible collection")
    parser.add_argument("--project-root", default=".", help="Project root directory")
    parser.add_argument("--output-json", default="quality-reports/quality-metrics.json", help="JSON output file")
    parser.add_argument("--output-md", default="quality-reports/QUALITY_REPORT.md", help="Markdown output file")
    parser.add_argument("--quiet", action="store_true", help="Suppress output messages")

    args = parser.parse_args()

    try:
        collector = QualityMetricsCollector(args.project_root)

        if not args.quiet:
            print("🔍 Starting quality metrics collection...")

        # Generate comprehensive report
        report = collector.generate_report()

        # Save reports
        collector.save_report(args.output_json)
        collector.generate_markdown_report(args.output_md)

        if not args.quiet:
            print(
                f"\n🎯 Quality Score: {report['metrics']['overall_score']['grade']} ({report['metrics']['overall_score']['overall_score']}/100)"
            )
            print(f"📊 Component Scores:")
            for component, data in report["metrics"]["overall_score"]["components"].items():
                print(f"   - {component.title()}: {data['score']}/100")

        return 0

    except Exception as e:
        print(f"❌ Error collecting quality metrics: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
