# Synaptic Trading Knowledge Vault

A collaborative Obsidian vault for Synaptic Trading development and knowledge management.

## Overview

This vault is designed for team collaboration using Git version control and GitHub for synchronization.

## Setup Instructions

### For New Collaborators

1. **Clone this repository**:
   ```bash
   git clone <repository-url>
   ```

2. **Open in Obsidian**:
   - Open Obsidian
   - Click "Open folder as vault"
   - Select the cloned `Synaptic_Trading_KnowledgeVault` folder

3. **Start collaborating**:
   - Create and edit notes as needed
   - Commit your changes regularly
   - Pull before you start working to get latest updates
   - Push your changes to share with the team

### Git Workflow for Collaboration

```bash
# Before starting work - get latest changes
git pull origin main

# After making changes
git add .
git commit -m "Description of your changes"
git push origin main
```

### Handling Merge Conflicts

If you encounter conflicts:
1. Open the conflicted file in Obsidian or a text editor
2. Look for conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
3. Choose which version to keep or merge them manually
4. Remove conflict markers
5. Commit the resolved changes

## Vault Structure

```
Synaptic_Trading_KnowledgeVault/
├── .obsidian/          # Obsidian configuration (synced)
├── attachments/        # Images and file attachments
├── templates/          # Note templates
└── README.md          # This file
```

## Best Practices

1. **Commit Often**: Make small, focused commits with clear messages
2. **Pull Regularly**: Always pull before starting new work
3. **Resolve Conflicts Promptly**: Address merge conflicts as soon as they occur
4. **Use Meaningful Names**: Name notes clearly and consistently
5. **Link Notes**: Use Obsidian's `[[wiki-links]]` to connect related notes

## Configuration

The `.obsidian` folder contains shared settings including:
- Core plugins configuration
- Appearance settings
- App settings

Note: Workspace layouts are NOT synced (they're in `.gitignore`) so each user can have their own window arrangement.

## Version

- Created: 2025-11-01
- Obsidian Version: Compatible with latest release
- Git: Enabled for collaboration

## Directory Structure

- `UPMS/` – Universal Product Methodology System. Holds reusable process playbooks, gate checklists, intake forms, sprint rituals, and governance notes that apply across products. No product-specific content should live here.
- `SynapticTrading_Product/` – Product knowledge base for the platform. Contains epics, PRDs, design references, research, strategy catalogue, sprint notes, and execution artefacts for the trading platform.
- `attachments/` – Shared images or assets referenced across notes.
- `templates/` – Obsidian templates for both methodology and product documentation.

Keep process documentation in `UPMS/` so any project can reuse it. Keep product-specific materials inside `SynapticTrading_Product/` to avoid mixing methodology with deliverables.
