# SynapticTrading Developer Manual

## Overview
This manual provides comprehensive development guidance for the SynapticTrading platform, covering APIs, integration patterns, and development workflows.

## Table of Contents

### Core Platform APIs
- [Backtesting Framework API](./backtesting_api.md) - EPIC-002 basic implementation
- [Advanced Backtesting API](./advanced_backtesting_api.md) - EPIC-002 advanced features (Node A)
- [Strategy Lifecycle API](./strategy_lifecycle_api.md) - EPIC-007 Git integration and A/B testing (Node B)  
- [Trading Adapters API](./trading_adapters_api.md) - EPIC-005 implementation
- [Data Pipeline API](./data_pipeline_api.md) - Data Pipeline v2 implementation (Node D)

### Integration Guides
- [Port Interfaces](./port_interfaces.md) - Domain port implementations
- [Enhanced Foundation](./enhanced_foundation.md) - EPIC-QUALITY-001 traceability patterns
- [Cross-Engine Integration](./cross_engine_integration.md) - Multi-engine development

### Development Workflows  
- [UPMS Development Cycle](./upms_development_cycle.md) - Proper EPIC/Sprint methodology
- [Git Workflow](./git_workflow.md) - Enhanced commit patterns with traceability
- [Testing Standards](./testing_standards.md) - Contract testing and validation
- [Code Review Process](./code_review_process.md) - Quality assurance procedures

### Compliance & Governance
- [Regulatory Compliance](./regulatory_compliance.md) - FINRA/SOX/FASB requirements
- [AI Agent Standards](./ai_agent_standards.md) - AI development governance
- [Traceability Requirements](./traceability_requirements.md) - Work item linking standards

## Quick Start for Developers

### Prerequisites
```bash
# Clone repository
git clone https://github.com/synaptic-algos/theplatform.git
cd SynapticTrading

# Set up vault integration
./scripts/KnowledgeVault/setup_vault_symlinks.sh

# Install development hooks  
./scripts/tools/install-hooks.sh

# Check vault status
make check-status
```

### Development Workflow
1. **Check Vault Artifacts**: Ensure EPIC/Feature/Story exists in vault
2. **Follow UPMS Standards**: Use proper templates and frontmatter
3. **Implement with Traceability**: Include work item references in all code
4. **Test Comprehensively**: Maintain >95% test coverage
5. **Update Progress**: Use `make sync-status` to track completion

### Code Standards
- **Financial Code**: Use Decimal arithmetic, include compliance context
- **Work Item Linking**: All code must reference valid EPIC/Feature/Story/Task
- **Enhanced Foundation**: Follow patterns from EPIC-QUALITY-001
- **Human Review**: Required for all financial calculations

## Architecture Overview

The SynapticTrading platform follows a port-adapter architecture with enhanced foundation integration:

### Core Components
- **Domain Layer**: Business logic and domain models
- **Application Layer**: Use cases and application services
- **Adapters Layer**: Framework-specific implementations (Backtrader, IB, etc.)
- **Infrastructure Layer**: Data persistence and external integrations

### Enhanced Foundation Benefits
All development builds on the enhanced foundation from EPIC-QUALITY-001:
- Complete traceability metadata for regulatory compliance
- Standardized work item linking patterns
- Integrated performance metrics and capital allocation
- Proven patterns for AI agent development

## Support & Resources

### Documentation Links
- **Vault Guide**: `documentation/vault_upms_templates/VAULT_GUIDE_Template.md`
- **UPMS Methodology**: `/Users/nitindhawan/KnowledgeVaults/UPMS_Vault/`
- **User Manual**: `documentation/user_manual/`
- **Admin Manual**: `documentation/administrator_manual/`

### Development Tools
- **Status Sync**: `make sync-status` - Update vault progress
- **Status Check**: `make check-status` - Validate compliance
- **Sprint Close**: `make sprint-close SPRINT=<id>` - Complete sprints

### Quality Gates
- Pre-commit hooks validate work item references
- Enhanced foundation provides proven patterns
- Cross-EPIC integration testing ensures consistency
- Regulatory compliance built into all financial code

For detailed API documentation and implementation guides, see the individual manual sections.