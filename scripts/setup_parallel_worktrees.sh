#!/bin/bash

# Parallel Development Worktree Setup Script
# Sets up Git worktrees for EPIC-005 and Unified Strategy parallel development

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MAIN_REPO="SynapticTrading"
EPIC005_DIR="SynapticTrading-EPIC005"
UNIFIED_STRATEGY_DIR="SynapticTrading-UnifiedStrategy"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a Git repository. Please run this script from the SynapticTrading repository root."
        exit 1
    fi
}

# Function to check if branch exists
branch_exists() {
    git rev-parse --verify "$1" >/dev/null 2>&1
}

# Function to setup EPIC-005 worktree
setup_epic005_worktree() {
    print_status "Setting up EPIC-005 worktree..."
    
    # Check if worktree directory already exists
    if [ -d "../${EPIC005_DIR}" ]; then
        print_warning "Directory ../${EPIC005_DIR} already exists. Skipping EPIC-005 worktree setup."
        return 0
    fi
    
    # Create and checkout EPIC-005 branch if it doesn't exist
    if ! branch_exists "feature/epic-005"; then
        print_status "Creating feature/epic-005 branch..."
        git checkout -b feature/epic-005
        git checkout main
    fi
    
    # Create worktree
    print_status "Creating EPIC-005 worktree at ../${EPIC005_DIR}..."
    git worktree add "../${EPIC005_DIR}" feature/epic-005
    
    # Setup EPIC-005 development branch
    cd "../${EPIC005_DIR}"
    print_status "Creating EPIC-005 development branch..."
    git checkout -b feature/epic-005-development
    
    # Create initial directory structure for EPIC-005
    print_status "Setting up EPIC-005 directory structure..."
    mkdir -p src/validation
    mkdir -p src/analytics
    mkdir -p src/engines/comparison
    mkdir -p tests/validation
    mkdir -p tests/analytics
    
    # Create placeholder files
    cat > src/validation/__init__.py << 'EOF'
"""
EPIC-005: Cross-Engine Validation
Validation components for cross-engine comparison and performance analytics
"""
EOF
    
    cat > src/analytics/__init__.py << 'EOF'
"""
EPIC-005: Performance Analytics
Analytics and reporting components for strategy performance analysis
"""
EOF
    
    print_success "EPIC-005 worktree setup complete at ../${EPIC005_DIR}"
    cd "../${MAIN_REPO}"
}

# Function to setup Unified Strategy worktree
setup_unified_strategy_worktree() {
    print_status "Setting up Unified Strategy worktree..."
    
    # Check if worktree directory already exists
    if [ -d "../${UNIFIED_STRATEGY_DIR}" ]; then
        print_warning "Directory ../${UNIFIED_STRATEGY_DIR} already exists. Skipping Unified Strategy worktree setup."
        return 0
    fi
    
    # Create and checkout Unified Strategy branch if it doesn't exist
    if ! branch_exists "feature/unified-strategy"; then
        print_status "Creating feature/unified-strategy branch..."
        git checkout -b feature/unified-strategy
        git checkout main
    fi
    
    # Create worktree
    print_status "Creating Unified Strategy worktree at ../${UNIFIED_STRATEGY_DIR}..."
    git worktree add "../${UNIFIED_STRATEGY_DIR}" feature/unified-strategy
    
    # Setup Unified Strategy development branch
    cd "../${UNIFIED_STRATEGY_DIR}"
    print_status "Creating Unified Strategy development branch..."
    git checkout -b feature/unified-strategy-development
    
    # Create initial directory structure for Unified Strategy
    print_status "Setting up Unified Strategy directory structure..."
    mkdir -p src/domain/orchestration
    mkdir -p src/domain/models
    mkdir -p src/domain/ports
    mkdir -p src/adapters/frameworks/backtest
    mkdir -p src/adapters/frameworks/paper
    mkdir -p src/adapters/frameworks/live
    mkdir -p tests/domain/orchestration
    mkdir -p tests/adapters
    
    # Create placeholder files for domain model
    cat > src/domain/orchestration/__init__.py << 'EOF'
"""
Unified Strategy Orchestration
Domain model for unified single/multi-strategy orchestration
"""
EOF
    
    cat > src/domain/orchestration/unified_strategy_orchestrator.py << 'EOF'
"""
Unified Strategy Orchestrator
Platform-agnostic orchestrator for both single and multi-strategy modes
"""

from typing import Dict, List, Any
from enum import Enum

class OrchestratorMode(Enum):
    SINGLE = "single"
    MULTI = "multi"

class UnifiedStrategyOrchestrator:
    """
    Platform-agnostic orchestrator for both single and multi-strategy modes.
    Handles N=1 (single-strategy) and N>1 (multi-strategy) cases.
    """
    
    def __init__(self):
        self.strategies = {}
        self.mode = None
        
    def detect_mode(self, config: Dict[str, Any]) -> OrchestratorMode:
        """Auto-detect mode from configuration structure."""
        if "strategy" in config:
            return OrchestratorMode.SINGLE
        elif "strategies" in config:
            return OrchestratorMode.MULTI
        else:
            raise ValueError("Invalid configuration format")
    
    def is_single_strategy_mode(self) -> bool:
        """Check if running in single-strategy mode."""
        return self.mode == OrchestratorMode.SINGLE
EOF
    
    cat > src/domain/orchestration/strategy_library.py << 'EOF'
"""
Strategy Library
Pre-defined strategies available for selection in single-strategy mode
"""

class StrategyLibrary:
    """Pre-defined strategies available for selection."""
    
    STRATEGIES = {
        "OPTIONS_MONTHLY_WEEKLY_HEDGE": "OptionsMonthlyWeeklyHedgeStrategy",
        "IRON_CONDOR": "IronCondorStrategy", 
        "BULL_CALL_SPREAD": "BullCallSpreadStrategy",
        "BEAR_PUT_SPREAD": "BearPutSpreadStrategy",
        "STRANGLE": "StrangleStrategy",
        "MOMENTUM_FUTURES": "MomentumFuturesStrategy",
        "MEAN_REVERSION_EQUITY": "MeanReversionEquityStrategy",
    }
    
    @classmethod
    def get_strategy(cls, name: str):
        """Get strategy instance from library."""
        if name not in cls.STRATEGIES:
            raise ValueError(f"Unknown strategy: {name}")
        # Implementation would load actual strategy class
        return None
    
    @classmethod
    def list_available(cls) -> List[str]:
        """List all available strategy names."""
        return list(cls.STRATEGIES.keys())
EOF
    
    print_success "Unified Strategy worktree setup complete at ../${UNIFIED_STRATEGY_DIR}"
    cd "../${MAIN_REPO}"
}

# Function to create coordination tools
setup_coordination_tools() {
    print_status "Setting up coordination tools..."
    
    # Create parallel development coordination script
    cat > scripts/parallel_dev_status.sh << 'EOF'
#!/bin/bash
# Parallel Development Status Script
# Shows status of both development worktrees

echo "=== Parallel Development Status ==="
echo ""

echo "📊 EPIC-005 Status:"
if [ -d "../SynapticTrading-EPIC005" ]; then
    cd "../SynapticTrading-EPIC005"
    echo "Branch: $(git branch --show-current)"
    echo "Last commit: $(git log -1 --oneline)"
    echo "Modified files:"
    git status --porcelain | head -5
    cd "../SynapticTrading"
else
    echo "❌ EPIC-005 worktree not found"
fi

echo ""
echo "🔧 Unified Strategy Status:"
if [ -d "../SynapticTrading-UnifiedStrategy" ]; then
    cd "../SynapticTrading-UnifiedStrategy"
    echo "Branch: $(git branch --show-current)"
    echo "Last commit: $(git log -1 --oneline)"
    echo "Modified files:"
    git status --porcelain | head -5
    cd "../SynapticTrading"
else
    echo "❌ Unified Strategy worktree not found"
fi

echo ""
echo "🔄 Integration Status:"
echo "Main branch: $(git branch --show-current)"
echo "Last sync: $(git log --oneline -1)"
EOF
    
    chmod +x scripts/parallel_dev_status.sh
    
    # Create conflict detection script
    cat > scripts/detect_conflicts.sh << 'EOF'
#!/bin/bash
# Conflict Detection Script
# Checks for potential merge conflicts between parallel branches

echo "🔍 Checking for potential conflicts..."

# Check if both worktrees exist
if [ ! -d "../SynapticTrading-EPIC005" ] || [ ! -d "../SynapticTrading-UnifiedStrategy" ]; then
    echo "❌ One or both worktrees not found"
    exit 1
fi

# Get list of modified files from EPIC-005
echo "📋 Files modified in EPIC-005:"
cd "../SynapticTrading-EPIC005"
epic005_files=$(git diff --name-only main)
echo "$epic005_files"

# Get list of modified files from Unified Strategy
echo ""
echo "📋 Files modified in Unified Strategy:"
cd "../SynapticTrading-UnifiedStrategy"
unified_files=$(git diff --name-only main)
echo "$unified_files"

# Check for overlapping files
echo ""
echo "⚠️  Potential conflicts:"
overlap=$(comm -12 <(echo "$epic005_files" | sort) <(echo "$unified_files" | sort))
if [ -z "$overlap" ]; then
    echo "✅ No overlapping files detected"
else
    echo "🔴 Overlapping files found:"
    echo "$overlap"
fi

cd "../SynapticTrading"
EOF
    
    chmod +x scripts/detect_conflicts.sh
    
    print_success "Coordination tools created in scripts/"
}

# Function to display post-setup instructions
show_instructions() {
    echo ""
    echo "════════════════════════════════════════════════════"
    print_success "Parallel Development Worktrees Setup Complete!"
    echo "════════════════════════════════════════════════════"
    echo ""
    echo "📁 Directory Structure:"
    echo "   $(pwd)                      # Main repository"
    echo "   ../${EPIC005_DIR}           # EPIC-005 development"
    echo "   ../${UNIFIED_STRATEGY_DIR}  # Unified Strategy development"
    echo ""
    echo "🔧 Development Workflow:"
    echo "   1. Work in respective worktrees:"
    echo "      cd ../${EPIC005_DIR}                    # For EPIC-005 work"
    echo "      cd ../${UNIFIED_STRATEGY_DIR}           # For Unified Strategy work"
    echo ""
    echo "   2. Check development status:"
    echo "      ./scripts/parallel_dev_status.sh"
    echo ""
    echo "   3. Detect potential conflicts:"
    echo "      ./scripts/detect_conflicts.sh"
    echo ""
    echo "   4. Coordinate via Slack channel: #parallel-dev-coordination"
    echo ""
    echo "⚠️  Important Notes:"
    echo "   - Always check for conflicts before major commits"
    echo "   - Sync with main branch weekly"
    echo "   - Communicate file changes in Slack"
    echo "   - Use feature flags for integration testing"
    echo ""
    print_warning "Next Steps:"
    echo "   1. Set up Slack channel: #parallel-dev-coordination"
    echo "   2. Schedule weekly sync meetings (Fridays 4 PM)"
    echo "   3. Begin development in respective worktrees"
    echo "   4. Follow the parallel development timeline"
}

# Main execution
main() {
    print_status "Starting parallel development worktree setup..."
    
    # Check prerequisites
    check_git_repo
    
    # Ensure we're on main branch
    current_branch=$(git branch --show-current)
    if [ "$current_branch" != "main" ]; then
        print_warning "Switching to main branch (currently on $current_branch)"
        git checkout main
    fi
    
    # Fetch latest changes
    print_status "Fetching latest changes..."
    git fetch origin
    
    # Setup worktrees
    setup_epic005_worktree
    setup_unified_strategy_worktree
    
    # Setup coordination tools
    setup_coordination_tools
    
    # Show instructions
    show_instructions
}

# Run main function
main "$@"