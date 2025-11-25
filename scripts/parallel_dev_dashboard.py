#!/usr/bin/env python3
"""
Parallel Development Dashboard
Real-time monitoring and coordination tool for EPIC-005 and Unified Strategy parallel development
"""

import os
import subprocess
import json
from datetime import datetime, timedelta
from pathlib import Path
import argparse
from typing import Dict, List, Optional, Tuple

class ParallelDevDashboard:
    def __init__(self):
        self.main_repo = Path.cwd()
        self.epic005_repo = self.main_repo.parent / "SynapticTrading-EPIC005"
        self.unified_repo = self.main_repo.parent / "SynapticTrading-UnifiedStrategy"
        
    def run_git_command(self, repo_path: Path, command: str) -> str:
        """Run git command in specified repository."""
        try:
            result = subprocess.run(
                f"git {command}",
                shell=True,
                cwd=repo_path,
                capture_output=True,
                text=True
            )
            return result.stdout.strip() if result.returncode == 0 else ""
        except Exception:
            return ""
    
    def get_branch_status(self, repo_path: Path) -> Dict[str, str]:
        """Get detailed branch status for a repository."""
        if not repo_path.exists():
            return {"status": "not_found", "error": f"Repository not found: {repo_path}"}
            
        status = {}
        status["current_branch"] = self.run_git_command(repo_path, "branch --show-current")
        status["last_commit"] = self.run_git_command(repo_path, "log -1 --oneline")
        status["last_commit_time"] = self.run_git_command(repo_path, "log -1 --format='%cr'")
        status["author"] = self.run_git_command(repo_path, "log -1 --format='%an'")
        status["commits_today"] = self.run_git_command(repo_path, "rev-list --count --since='1 day ago' HEAD")
        status["modified_files"] = self.run_git_command(repo_path, "status --porcelain").count('\n') if self.run_git_command(repo_path, "status --porcelain") else 0
        status["ahead_behind"] = self.run_git_command(repo_path, "rev-list --left-right --count origin/main...HEAD")
        
        return status
    
    def detect_file_conflicts(self) -> List[str]:
        """Detect potential file conflicts between the two development streams."""
        if not self.epic005_repo.exists() or not self.unified_repo.exists():
            return []
            
        epic005_files = set(self.run_git_command(self.epic005_repo, "diff --name-only main").split('\n'))
        unified_files = set(self.run_git_command(self.unified_repo, "diff --name-only main").split('\n'))
        
        # Remove empty strings
        epic005_files = {f for f in epic005_files if f}
        unified_files = {f for f in unified_files if f}
        
        conflicts = epic005_files.intersection(unified_files)
        return list(conflicts)
    
    def get_commit_activity(self, repo_path: Path, days: int = 7) -> List[Dict[str, str]]:
        """Get recent commit activity for a repository."""
        if not repo_path.exists():
            return []
            
        commits = self.run_git_command(
            repo_path, 
            f"log --since='{days} days ago' --format='%h|%an|%cr|%s'"
        )
        
        activity = []
        for line in commits.split('\n'):
            if line:
                parts = line.split('|', 3)
                if len(parts) == 4:
                    activity.append({
                        "hash": parts[0],
                        "author": parts[1],
                        "time": parts[2],
                        "message": parts[3]
                    })
        
        return activity
    
    def generate_status_report(self) -> Dict[str, any]:
        """Generate comprehensive status report."""
        report = {
            "timestamp": datetime.now().isoformat(),
            "epic005": self.get_branch_status(self.epic005_repo),
            "unified_strategy": self.get_branch_status(self.unified_repo),
            "main": self.get_branch_status(self.main_repo),
            "conflicts": self.detect_file_conflicts(),
            "epic005_activity": self.get_commit_activity(self.epic005_repo),
            "unified_activity": self.get_commit_activity(self.unified_repo)
        }
        
        return report
    
    def print_status_dashboard(self):
        """Print formatted status dashboard."""
        report = self.generate_status_report()
        
        print("=" * 80)
        print("🚀 PARALLEL DEVELOPMENT DASHBOARD")
        print(f"📅 {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("=" * 80)
        
        # EPIC-005 Status
        print("\n📊 EPIC-005 STATUS")
        print("-" * 40)
        epic005 = report["epic005"]
        if "error" in epic005:
            print(f"❌ {epic005['error']}")
        else:
            print(f"🌿 Branch: {epic005['current_branch']}")
            print(f"📝 Last commit: {epic005['last_commit']}")
            print(f"⏰ When: {epic005['last_commit_time']}")
            print(f"👤 Author: {epic005['author']}")
            print(f"📈 Commits today: {epic005['commits_today']}")
            print(f"📄 Modified files: {epic005['modified_files']}")
        
        # Unified Strategy Status
        print("\n🔧 UNIFIED STRATEGY STATUS")
        print("-" * 40)
        unified = report["unified_strategy"]
        if "error" in unified:
            print(f"❌ {unified['error']}")
        else:
            print(f"🌿 Branch: {unified['current_branch']}")
            print(f"📝 Last commit: {unified['last_commit']}")
            print(f"⏰ When: {unified['last_commit_time']}")
            print(f"👤 Author: {unified['author']}")
            print(f"📈 Commits today: {unified['commits_today']}")
            print(f"📄 Modified files: {unified['modified_files']}")
        
        # Conflict Detection
        print("\n⚠️  CONFLICT ANALYSIS")
        print("-" * 40)
        conflicts = report["conflicts"]
        if conflicts:
            print(f"🔴 {len(conflicts)} potential conflicts detected:")
            for conflict in conflicts[:5]:  # Show first 5
                print(f"   • {conflict}")
            if len(conflicts) > 5:
                print(f"   ... and {len(conflicts) - 5} more")
        else:
            print("✅ No file conflicts detected")
        
        # Recent Activity
        print("\n📈 RECENT ACTIVITY (Last 3 commits)")
        print("-" * 40)
        
        print("EPIC-005:")
        for commit in report["epic005_activity"][:3]:
            print(f"  {commit['hash']} • {commit['author']} • {commit['time']}")
            print(f"    {commit['message']}")
        
        print("\nUnified Strategy:")
        for commit in report["unified_activity"][:3]:
            print(f"  {commit['hash']} • {commit['author']} • {commit['time']}")
            print(f"    {commit['message']}")
        
        # Integration Status
        print("\n🔄 INTEGRATION STATUS")
        print("-" * 40)
        self.print_integration_status()
        
        print("\n" + "=" * 80)
    
    def print_integration_status(self):
        """Print integration branch status."""
        # Check for integration branches
        integration_branches = self.run_git_command(
            self.main_repo, 
            "branch -r | grep integration"
        )
        
        if integration_branches:
            print("🔄 Integration branches found:")
            for branch in integration_branches.split('\n'):
                if branch.strip():
                    print(f"  • {branch.strip()}")
        else:
            print("📝 No active integration branches")
        
        # Check last integration
        last_merge = self.run_git_command(
            self.main_repo,
            "log --merges -1 --format='%h %cr - %s'"
        )
        if last_merge:
            print(f"🔗 Last integration: {last_merge}")
    
    def check_worktree_health(self):
        """Check health of worktree setup."""
        print("🏥 WORKTREE HEALTH CHECK")
        print("-" * 40)
        
        # Check worktree list
        worktrees = self.run_git_command(self.main_repo, "worktree list")
        if worktrees:
            print("📂 Active worktrees:")
            for line in worktrees.split('\n'):
                if line:
                    print(f"  {line}")
        else:
            print("❌ No worktrees found - run setup script?")
        
        # Check for worktree issues
        epic005_exists = self.epic005_repo.exists()
        unified_exists = self.unified_repo.exists()
        
        print(f"\n🔍 Worktree Status:")
        print(f"  EPIC-005: {'✅ Ready' if epic005_exists else '❌ Missing'}")
        print(f"  Unified Strategy: {'✅ Ready' if unified_exists else '❌ Missing'}")
        
        if not epic005_exists or not unified_exists:
            print("\n💡 Run setup script: ./scripts/setup_parallel_worktrees.sh")
    
    def export_json_report(self, filename: Optional[str] = None):
        """Export detailed report as JSON."""
        if filename is None:
            filename = f"parallel_dev_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        report = self.generate_status_report()
        
        with open(filename, 'w') as f:
            json.dump(report, f, indent=2)
        
        print(f"📄 Report exported to: {filename}")
    
    def watch_mode(self, interval: int = 30):
        """Run dashboard in watch mode with auto-refresh."""
        import time
        
        try:
            while True:
                os.system('clear')  # Clear screen
                self.print_status_dashboard()
                print(f"\n🔄 Refreshing in {interval} seconds... (Ctrl+C to exit)")
                time.sleep(interval)
        except KeyboardInterrupt:
            print("\n👋 Dashboard stopped")

def main():
    parser = argparse.ArgumentParser(description="Parallel Development Dashboard")
    parser.add_argument("--watch", action="store_true", help="Run in watch mode")
    parser.add_argument("--interval", type=int, default=30, help="Refresh interval for watch mode (seconds)")
    parser.add_argument("--export", type=str, help="Export JSON report to file")
    parser.add_argument("--health", action="store_true", help="Check worktree health")
    
    args = parser.parse_args()
    
    dashboard = ParallelDevDashboard()
    
    if args.health:
        dashboard.check_worktree_health()
    elif args.export:
        dashboard.export_json_report(args.export)
    elif args.watch:
        dashboard.watch_mode(args.interval)
    else:
        dashboard.print_status_dashboard()

if __name__ == "__main__":
    main()