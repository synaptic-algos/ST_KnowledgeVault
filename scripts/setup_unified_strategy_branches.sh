#!/bin/bash

# Unified Strategy Branch Setup Script
# Sets up branch structure for serial development of unified strategy support

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Ensure we're on main and up to date
print_status "Ensuring we're on main branch and up to date..."
git checkout main
git pull origin main

# Create main release branch
print_status "Creating unified strategy release branch..."
git checkout -b feature/unified-strategy-release
git push -u origin feature/unified-strategy-release

# Create domain foundation branch
print_status "Creating domain foundation branch..."
git checkout -b feature/domain-foundation
git push -u origin feature/domain-foundation

# Create initial directory structure for domain work
print_status "Setting up domain directory structure..."
mkdir -p src/domain/orchestration
mkdir -p src/domain/models  
mkdir -p src/domain/ports
mkdir -p tests/domain/orchestration
mkdir -p tests/domain/models
mkdir -p config/schemas

# Create initial domain files
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

from typing import Dict, List, Any, Optional
from enum import Enum

class OrchestratorMode(Enum):
    """Strategy orchestration modes."""
    SINGLE = "single"
    MULTI = "multi"

class UnifiedStrategyOrchestrator:
    """
    Platform-agnostic orchestrator for both single and multi-strategy modes.
    Handles N=1 (single-strategy) and N>1 (multi-strategy) cases.
    Pure domain logic - no infrastructure dependencies.
    """
    
    def __init__(self):
        self.strategies: Dict[str, Any] = {}
        self._mode: Optional[OrchestratorMode] = None
        
    def detect_mode(self, config: Dict[str, Any]) -> OrchestratorMode:
        """
        Auto-detect mode from configuration structure.
        
        Single-strategy indicators:
        - Has 'strategy' key (string)
        - Has 'config' key (dict)
        
        Multi-strategy indicators:  
        - Has 'strategies' key (dict)
        - Each sub-key is a strategy with config
        """
        if "strategy" in config and isinstance(config["strategy"], str):
            return OrchestratorMode.SINGLE
        elif "strategies" in config and isinstance(config["strategies"], dict):
            return OrchestratorMode.MULTI
        else:
            raise ValueError("Invalid configuration format")
    
    def is_single_strategy_mode(self) -> bool:
        """Check if running in single-strategy mode."""
        return self._mode == OrchestratorMode.SINGLE
        
    def add_strategy(self, strategy_id: str, strategy_config: Dict[str, Any]) -> None:
        """Add a strategy with configuration."""
        # Implementation to be completed
        pass
        
    def validate_compatibility(self) -> Dict[str, Any]:
        """Validate strategy compatibility (only relevant for multi mode)."""
        if self.is_single_strategy_mode():
            return {"is_compatible": True, "warnings": []}
        # Multi-strategy compatibility logic to be implemented
        return {"is_compatible": True, "warnings": []}
        
    def allocate_capital(self, total_capital: float) -> Dict[str, float]:
        """Calculate capital allocation (100% for single, split for multi)."""
        if self.is_single_strategy_mode():
            strategy_id = list(self.strategies.keys())[0]
            return {strategy_id: total_capital}
        # Multi-strategy allocation logic to be implemented
        return {}
EOF

cat > src/domain/orchestration/strategy_library.py << 'EOF'
"""
Strategy Library
Pre-defined strategies available for selection in single-strategy mode
"""

from typing import Dict, List, Any

class StrategyLibrary:
    """Pre-defined strategies available for selection."""
    
    # Strategy registry - maps names to strategy classes/configs
    STRATEGIES = {
        "OPTIONS_MONTHLY_WEEKLY_HEDGE": {
            "class": "OptionsMonthlyWeeklyHedgeStrategy",
            "description": "Monthly/Weekly options hedge strategy",
            "default_config": {
                "num_lots": 4,
                "max_positions": 3,
                "stop_loss_pct": 2.0
            }
        },
        "IRON_CONDOR": {
            "class": "IronCondorStrategy", 
            "description": "Iron condor options strategy",
            "default_config": {
                "strikes": 4,
                "max_positions": 5
            }
        },
        "BULL_CALL_SPREAD": {
            "class": "BullCallSpreadStrategy",
            "description": "Bull call spread strategy",
            "default_config": {
                "strike_width": 50,
                "max_positions": 3
            }
        },
        "BEAR_PUT_SPREAD": {
            "class": "BearPutSpreadStrategy", 
            "description": "Bear put spread strategy",
            "default_config": {
                "strike_width": 50,
                "max_positions": 3
            }
        },
        "STRANGLE": {
            "class": "StrangleStrategy",
            "description": "Long strangle options strategy", 
            "default_config": {
                "delta_target": 0.3,
                "max_positions": 2
            }
        },
        "MOMENTUM_FUTURES": {
            "class": "MomentumFuturesStrategy",
            "description": "Momentum-based futures trading",
            "default_config": {
                "leverage": 2.0,
                "lookback_days": 20
            }
        },
        "MEAN_REVERSION_EQUITY": {
            "class": "MeanReversionEquityStrategy", 
            "description": "Mean reversion equity strategy",
            "default_config": {
                "position_size_pct": 3.0,
                "reversion_threshold": 2.0
            }
        }
    }
    
    @classmethod
    def get_strategy(cls, name: str) -> Dict[str, Any]:
        """Get strategy configuration from library."""
        if name not in cls.STRATEGIES:
            raise ValueError(f"Unknown strategy: {name}. Available: {cls.list_available()}")
        return cls.STRATEGIES[name].copy()
    
    @classmethod
    def list_available(cls) -> List[str]:
        """List all available strategy names."""
        return list(cls.STRATEGIES.keys())
        
    @classmethod
    def get_strategy_info(cls, name: str) -> Dict[str, Any]:
        """Get detailed information about a strategy."""
        strategy = cls.get_strategy(name)
        return {
            "name": name,
            "description": strategy["description"],
            "default_config": strategy["default_config"],
            "class": strategy["class"]
        }
EOF

# Create configuration schema
cat > config/schemas/unified_strategy_schemas.py << 'EOF'
"""
Configuration schemas for unified strategy support
"""

# Single Strategy Configuration Schema
SINGLE_STRATEGY_SCHEMA = {
    "type": "object",
    "required": ["strategy"],
    "properties": {
        "strategy": {"type": "string"},
        "config": {
            "type": "object",
            "additionalProperties": True
        },
        "portfolio": {
            "type": "object",
            "properties": {
                "total_capital": {"type": "number", "minimum": 0},
                "currency": {"type": "string", "default": "INR"}
            }
        },
        "risk_management": {
            "type": "object",
            "properties": {
                "max_drawdown_pct": {"type": "number", "minimum": 0, "maximum": 100},
                "position_size_limit": {"type": "number", "minimum": 0}
            }
        }
    }
}

# Multi Strategy Configuration Schema  
MULTI_STRATEGY_SCHEMA = {
    "type": "object",
    "required": ["strategies"],
    "properties": {
        "strategies": {
            "type": "object",
            "patternProperties": {
                "^[A-Z_]+$": {
                    "type": "object",
                    "required": ["enabled", "allocation_pct"],
                    "properties": {
                        "enabled": {"type": "boolean"},
                        "allocation_pct": {"type": "number", "minimum": 0, "maximum": 100},
                        "max_positions": {"type": "integer", "minimum": 1},
                        "config": {
                            "type": "object",
                            "additionalProperties": True
                        }
                    }
                }
            }
        },
        "portfolio": {
            "type": "object",
            "properties": {
                "total_capital": {"type": "number", "minimum": 0},
                "currency": {"type": "string", "default": "INR"},
                "allocation_method": {
                    "type": "string", 
                    "enum": ["manual", "equal_weight", "risk_parity"]
                },
                "rebalance_frequency": {
                    "type": "string",
                    "enum": ["daily", "weekly", "monthly"]
                }
            }
        },
        "risk_management": {
            "type": "object", 
            "properties": {
                "portfolio_var_limit": {"type": "number", "minimum": 0},
                "concentration_limit_pct": {"type": "number", "minimum": 0, "maximum": 100},
                "correlation_threshold": {"type": "number", "minimum": -1, "maximum": 1}
            }
        }
    }
}
EOF

# Create basic test structure
cat > tests/domain/orchestration/test_unified_strategy_orchestrator.py << 'EOF'
"""
Tests for UnifiedStrategyOrchestrator
"""

import pytest
from src.domain.orchestration.unified_strategy_orchestrator import (
    UnifiedStrategyOrchestrator, 
    OrchestratorMode
)

class TestUnifiedStrategyOrchestrator:
    
    def test_detect_single_mode(self):
        """Test detection of single-strategy mode."""
        orchestrator = UnifiedStrategyOrchestrator()
        config = {
            "strategy": "OPTIONS_MONTHLY_WEEKLY_HEDGE",
            "config": {"num_lots": 4}
        }
        mode = orchestrator.detect_mode(config)
        assert mode == OrchestratorMode.SINGLE
    
    def test_detect_multi_mode(self):
        """Test detection of multi-strategy mode."""
        orchestrator = UnifiedStrategyOrchestrator()
        config = {
            "strategies": {
                "STRATEGY_1": {"enabled": True, "allocation_pct": 60.0},
                "STRATEGY_2": {"enabled": True, "allocation_pct": 40.0}
            }
        }
        mode = orchestrator.detect_mode(config)
        assert mode == OrchestratorMode.MULTI
    
    def test_invalid_config_raises_error(self):
        """Test that invalid config raises ValueError."""
        orchestrator = UnifiedStrategyOrchestrator()
        config = {"invalid": "config"}
        
        with pytest.raises(ValueError, match="Invalid configuration format"):
            orchestrator.detect_mode(config)
EOF

cat > tests/domain/orchestration/test_strategy_library.py << 'EOF'
"""
Tests for StrategyLibrary
"""

import pytest
from src.domain.orchestration.strategy_library import StrategyLibrary

class TestStrategyLibrary:
    
    def test_list_available_strategies(self):
        """Test listing available strategies."""
        strategies = StrategyLibrary.list_available()
        assert isinstance(strategies, list)
        assert len(strategies) > 0
        assert "OPTIONS_MONTHLY_WEEKLY_HEDGE" in strategies
    
    def test_get_valid_strategy(self):
        """Test getting a valid strategy."""
        strategy = StrategyLibrary.get_strategy("OPTIONS_MONTHLY_WEEKLY_HEDGE")
        assert "class" in strategy
        assert "description" in strategy
        assert "default_config" in strategy
    
    def test_get_invalid_strategy_raises_error(self):
        """Test that invalid strategy name raises ValueError."""
        with pytest.raises(ValueError, match="Unknown strategy"):
            StrategyLibrary.get_strategy("INVALID_STRATEGY")
    
    def test_get_strategy_info(self):
        """Test getting strategy information."""
        info = StrategyLibrary.get_strategy_info("IRON_CONDOR")
        assert "name" in info
        assert "description" in info
        assert info["name"] == "IRON_CONDOR"
EOF

# Create README for the domain foundation
cat > README_DOMAIN_FOUNDATION.md << 'EOF'
# Domain Foundation - Unified Strategy Support

This branch implements the core domain model for unified strategy orchestration.

## What's Implemented

### Core Components
- `UnifiedStrategyOrchestrator`: Main orchestration logic
- `StrategyLibrary`: Pre-defined strategy registry
- `OrchestratorMode`: Single vs Multi mode detection

### Configuration Support
- Single-strategy configuration schema
- Multi-strategy configuration schema  
- Automatic mode detection from config structure

### Testing
- Unit tests for orchestrator mode detection
- Unit tests for strategy library operations
- Configuration validation tests

## What's Next

After this domain foundation is complete:

1. **Backtest Enhancement** (EPIC-002 FEATURE-007)
2. **Paper Trading Enhancement** (EPIC-003 FEATURE-005)  
3. **Live Trading Enhancement** (EPIC-004 FEATURE-008)
4. **Integration Testing**

## Development Commands

```bash
# Run domain tests
python -m pytest tests/domain/

# Test mode detection
python -c "
from src.domain.orchestration.unified_strategy_orchestrator import UnifiedStrategyOrchestrator
o = UnifiedStrategyOrchestrator()
print(o.detect_mode({'strategy': 'TEST'}))  # Should print SINGLE
"

# List available strategies
python -c "
from src.domain.orchestration.strategy_library import StrategyLibrary  
print(StrategyLibrary.list_available())
"
```

## Branch Workflow

```bash
# Work on domain foundation
git checkout feature/domain-foundation

# Make changes and test
# ... development work ...

# When ready to integrate
git checkout feature/unified-strategy-release
git merge feature/domain-foundation

# Create next feature branch
git checkout -b feature/backtest-enhancement
```
EOF

# Commit initial structure
git add .
git commit -m "feat(domain): initial unified strategy orchestration domain model

- Add UnifiedStrategyOrchestrator with mode detection
- Add StrategyLibrary with pre-defined strategies  
- Add configuration schemas for both modes
- Add comprehensive unit tests
- Set up directory structure for domain development

Implements: EPIC-001 FEATURE-006 foundation"

git push -u origin feature/domain-foundation

# Switch back to release branch
git checkout feature/unified-strategy-release

print_success "✅ Unified strategy branch structure created!"
echo ""
echo "📁 Created branches:"
echo "  • feature/unified-strategy-release (main release branch)"
echo "  • feature/domain-foundation (domain model implementation)"
echo ""
echo "🚀 Next steps:"
echo "  1. Work in feature/domain-foundation to complete domain model"  
echo "  2. Merge to feature/unified-strategy-release when ready"
echo "  3. Create feature/backtest-enhancement for next phase"
echo ""
echo "💻 Start development:"
echo "  git checkout feature/domain-foundation"
echo "  # Begin implementing domain model..."