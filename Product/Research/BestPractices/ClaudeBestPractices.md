# Claude Code Best Practices

## Overview

This document captures best practices for working with Claude Code, Anthropic's official CLI for software development. These practices improve development velocity, code quality, and context efficiency.

**Last Updated**: 2025-11-19

---

## Table of Contents

1. [Available Agents](#available-agents)
2. [Agent Usage Patterns](#agent-usage-patterns)
3. [Context Management](#context-management)
4. [Task Planning](#task-planning)
5. [Communication Patterns](#communication-patterns)
6. [Tool Selection](#tool-selection)
7. [Git Workflow](#git-workflow)

---

## Available Agents

Claude Code provides specialized agents accessible through the Task tool. These agents work autonomously on specific tasks without cluttering the main conversation.

### 1. Explore Agent (Most Commonly Used)

**Purpose**: Fast codebase exploration and analysis

**Use For**:
- Finding files by patterns (`src/components/**/*.tsx`)
- Searching code for keywords ("API endpoints", "authentication")
- Answering questions about codebase structure
- Understanding how features work
- Discovering implementation patterns

**Thoroughness Levels**:
- `"quick"` - Basic searches, single-pass exploration
- `"medium"` - Moderate exploration across multiple locations
- `"very thorough"` - Comprehensive analysis across multiple locations and naming conventions

**Example Requests**:
```
"Explore the authentication flow in the codebase"
"Find all files related to market data processing"
"How does the strategy lifecycle state machine work?"
"Where are errors from the client handled?"
```

**When to Use**:
- Open-ended exploration (not needle queries for specific files)
- Understanding architectural patterns
- Discovering feature implementations
- Mapping dependencies

### 2. Plan Agent

**Purpose**: Planning implementation steps

**Use For**:
- Breaking down complex features into steps
- Creating implementation strategies
- Analyzing architectural approaches
- Designing solutions before coding

**Example Requests**:
```
"Plan an implementation for adding WebSocket support"
"Design a strategy for refactoring the execution engine"
"Break down the backtesting feature into implementation steps"
```

### 3. General-Purpose Agent

**Purpose**: Complex multi-step tasks requiring research and analysis

**Use For**:
- Research requiring multiple search iterations
- Tasks needing file reads, searches, and analysis
- Complex code investigations spanning multiple files
- Cross-cutting concerns analysis

**Example Requests**:
```
"Research all error handling patterns in the codebase"
"Analyze how the system handles market data updates"
"Investigate performance bottlenecks in the tick dispatcher"
```

### 4. Specialized Setup Agents

**statusline-setup**: Configure Claude Code status line setting
**output-style-setup**: Create custom output styles

---

## Agent Usage Patterns

### Automatic Invocation

You don't need to explicitly request agents - Claude Code automatically selects and invokes the appropriate agent based on your natural language requests.

**Examples**:

```
❌ Don't say: "Use the Explore agent to find authentication code"
✅ Do say: "Find all authentication-related code"

❌ Don't say: "Launch a Plan agent for this feature"
✅ Do say: "Plan the implementation for this feature"
```

### When NOT to Use Agents

Prefer direct tools over agents for:
- Reading a specific known file path → Use `Read` tool
- Searching for a specific class definition → Use `Glob` tool
- Searching code within 2-3 known files → Use `Read` tool
- Simple, single-step operations

### Parallel Agent Execution

Claude Code can run multiple agents simultaneously for independent tasks:

```
"Find all trading strategy files AND explain the portfolio management architecture"
```

This launches two Explore agents in parallel, maximizing performance.

---

## Context Management

### Benefits of Agents for Context Efficiency

**Without Agents** (inefficient):
- Multiple grep/glob commands clutter the conversation
- Intermediate search results consume context tokens
- Harder to track the conversation flow

**With Agents** (efficient):
- Agents work in isolated contexts
- Only relevant findings returned to main conversation
- Clean, focused results
- Significant context token savings

### Best Practices

1. **Use agents for exploration** - Let agents handle multi-step searches
2. **Keep main conversation focused** - Agents return only key findings
3. **Avoid manual searches** - Don't run grep/glob manually for open-ended searches
4. **Trust agent results** - Agents are specialized and optimized for their tasks

---

## Task Planning

### Use TodoWrite Tool Frequently

Claude Code provides the `TodoWrite` tool for task management. Use it proactively for:

1. **Complex multi-step tasks** - 3+ distinct steps
2. **Non-trivial tasks** - Requiring careful planning
3. **Multiple user requests** - Numbered or comma-separated lists
4. **Tracking progress** - Give user visibility into progress

### Task Management Rules

**Critical Rules**:
- Mark todos as `in_progress` BEFORE starting work
- ONLY ONE task can be `in_progress` at a time
- Mark tasks `completed` IMMEDIATELY after finishing (don't batch)
- Remove irrelevant tasks entirely

**Task States**:
- `pending` - Not yet started
- `in_progress` - Currently working (exactly ONE at a time)
- `completed` - Successfully finished

**Task Descriptions**:
Each task needs TWO forms:
- `content`: Imperative form ("Run tests", "Build the project")
- `activeForm`: Present continuous form ("Running tests", "Building the project")

### When to Use TodoWrite

**Use for**:
- Complex features requiring multiple steps
- Debugging involving multiple files
- Refactoring across multiple modules
- Any task with 3+ sub-tasks

**Don't Use for**:
- Single, straightforward tasks
- Trivial operations
- Tasks completable in <3 steps
- Purely conversational/informational requests

### Example Workflow

```
User: "Run the build and fix any type errors"

Claude:
1. Creates todos: "Run build", "Fix type errors"
2. Marks "Run build" as in_progress
3. Runs build
4. Marks "Run build" as completed
5. Creates 10 specific todos for each error
6. Works through each error, marking in_progress → completed
```

---

## Communication Patterns

### Professional Objectivity

**Prioritize**:
- Technical accuracy over validation
- Facts over emotional validation
- Honest disagreement over false agreement
- Objective guidance over excessive praise

**Avoid**:
- Over-the-top validation ("You're absolutely right!")
- Unnecessary superlatives
- Emotional validation
- False agreement when technically incorrect

### Tone and Style

**Guidelines**:
- Short, concise responses (CLI context)
- GitHub-flavored Markdown for formatting
- Monospace font rendering (CommonMark spec)
- **NO EMOJIS** unless explicitly requested by user
- Output text for communication, tools for tasks
- Never use bash echo or comments to communicate with user

### Code References

Always include `file_path:line_number` pattern when referencing code:

```
✅ "Clients are marked as failed in `connectToServer` function in src/services/process.ts:712"
❌ "The error is handled in the connectToServer function"
```

---

## Tool Selection

### Use Specialized Tools Over Bash

**Prefer specialized tools**:
- `Read` instead of `cat/head/tail`
- `Edit` instead of `sed/awk`
- `Write` instead of `cat` with heredoc or `echo >`
- `Glob` instead of `find` or `ls`
- `Grep` instead of `grep/rg`

**Reserve Bash for**:
- Actual system commands
- Terminal operations requiring shell execution
- Git operations
- Package manager commands (npm, pip, etc.)
- Test runners
- Build commands

### Parallel Tool Execution

When calling multiple independent tools, call them in parallel within a single response:

```
✅ Single message with parallel Read calls for multiple files
❌ Sequential messages for each file read

✅ Parallel git status and git diff calls
❌ git status, wait, then git diff
```

### When Tools Depend on Each Other

Use sequential execution when tools have dependencies:

```
✅ Write file, THEN git add && git commit (sequential)
❌ Write file and git commit in parallel (fails - file not written yet)

✅ mkdir directory, THEN copy files (sequential)
❌ mkdir and cp in parallel (fails - directory doesn't exist)
```

---

## Git Workflow

### Commit Message Format

Follow the repository's traceability pattern:

```
[STORY-ID][TASK-ID] Brief description

- Detailed change 1
- Detailed change 2
- Coverage/test info

Refs: vault_epics/EPIC-XXX/STORY-XXX.md
Progress: 25% → 45%
```

### Git Safety Protocol

**NEVER**:
- Update git config without permission
- Run destructive commands (force push, hard reset) without explicit request
- Skip hooks (--no-verify, --no-gpg-sign) without request
- Force push to main/master
- Commit changes unless explicitly asked

**ALWAYS**:
- Check authorship before amending: `git log -1 --format='%an %ae'`
- Use heredoc for commit messages (proper formatting)
- Run git status after commits to verify success
- Stage relevant files before committing

### Pull Request Creation

When creating PRs:

1. Run parallel status checks:
   - `git status` - Check untracked files
   - `git diff` - See staged/unstaged changes
   - Check remote tracking and sync status
   - `git log` and `git diff [base]...HEAD` - Full commit history

2. Analyze ALL commits (not just latest)

3. Create PR with gh CLI using heredoc for body:
```bash
gh pr create --title "Title" --body "$(cat <<'EOF'
## Summary
- Bullet points

## Test plan
- Checklist

🤖 Generated with Claude Code
EOF
)"
```

---

## Additional Best Practices

### Documentation Management

**Never**:
- Duplicate vault content in code repository
- Copy content from `vault_*` symlinks into local docs
- Create parallel documentation versions

**Always**:
- Reference vault content via symlinks
- Update documentation directly in vault (not via symlinks)
- Link git commits to vault Story/Task IDs
- Use local `documentation/` only for code-specific technical docs

### File Operations

**ALWAYS**:
- Prefer editing existing files over creating new ones
- Use `Read` tool before using `Write` on existing files
- Avoid creating markdown files unless absolutely necessary
- Never proactively create documentation files unless requested

### Hook Handling

Users may configure hooks (shell commands) that execute on events:
- Treat hook feedback as coming from the user
- If blocked by hook, adjust actions in response
- If unable to adjust, ask user to check hooks configuration

---

## Quick Reference

| Task Type | Agent/Tool | Example |
|-----------|------------|---------|
| Find files by pattern | Explore Agent | "Find all strategy files" |
| Search code for keywords | Explore Agent | "Find authentication code" |
| Understand architecture | Explore Agent | "How does the data pipeline work?" |
| Plan implementation | Plan Agent | "Plan WebSocket feature" |
| Complex research | General Agent | "Research all error handling patterns" |
| Read specific file | `Read` tool | Read known file path |
| Search in 2-3 files | `Read` tool | Read and search manually |
| Edit existing code | `Edit` tool | Make specific code changes |
| Create new file | `Write` tool | Write new file content |
| Find files by glob | `Glob` tool | Pattern matching for files |
| Search file contents | `Grep` tool | Content search |

---

## Learning More

- **Help**: Use `/help` command in Claude Code
- **Feedback**: Report issues at https://github.com/anthropics/claude-code/issues
- **Documentation**: https://docs.claude.com/en/docs/claude-code/

---

## Revision History

| Date | Changes | Author |
|------|---------|--------|
| 2025-11-19 | Initial creation | Nitin Dhawan |

---

## Related Documents

- [UPMS Methodology Blueprint](/Users/nitindhawan/KnowledgeVaults/UPMS_Vault/Methodology/UPMS_Methodology_Blueprint.md)
- [Git Workflow Standards](/Users/nitindhawan/KnowledgeVaults/UPMS_Vault/Methodology/Git_Workflow_Standards.md)
- [THREE_VAULT_ARCHITECTURE](/Users/nitindhawan/KnowledgeVaults/UPMS_Vault/THREE_VAULT_ARCHITECTURE.md)
