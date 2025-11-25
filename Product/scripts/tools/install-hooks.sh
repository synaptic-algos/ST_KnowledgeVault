#!/bin/bash
# Install git hooks for vault-code sync enforcement

set -e

REPO_ROOT=$(git rev-parse --show-toplevel)
HOOKS_DIR="$REPO_ROOT/.githooks"
GIT_HOOKS_DIR="$REPO_ROOT/.git/hooks"

echo "🔧 Installing git hooks for vault-code sync enforcement..."

# Check if we're in a git repository
if [ ! -d "$REPO_ROOT/.git" ]; then
    echo "❌ ERROR: Not in a git repository"
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Check if pre-commit hook exists
if [ ! -f "$HOOKS_DIR/pre-commit" ]; then
    echo "❌ ERROR: Pre-commit hook not found at $HOOKS_DIR/pre-commit"
    echo "Please ensure the vault sync pre-commit hook is present"
    exit 1
fi

# Make hooks executable
chmod +x "$HOOKS_DIR/pre-commit"

# Create symlink for pre-commit hook
echo "📎 Creating symlink for pre-commit hook..."
ln -sf "$HOOKS_DIR/pre-commit" "$GIT_HOOKS_DIR/pre-commit"

# Configure git to use our hooks directory
echo "⚙️  Configuring git to use hooks directory..."
git config core.hooksPath "$HOOKS_DIR"

# Verify installation
echo ""
echo "🔍 Verifying installation..."

if [ -L "$GIT_HOOKS_DIR/pre-commit" ]; then
    echo "✅ Pre-commit hook symlink created successfully"
else
    echo "⚠️  WARNING: Pre-commit hook symlink creation may have failed"
fi

if [ "$(git config core.hooksPath)" = "$HOOKS_DIR" ]; then
    echo "✅ Git hooks path configured correctly"
else
    echo "⚠️  WARNING: Git hooks path configuration may have failed"
fi

echo ""
echo "✅ Git hooks installation complete!"
echo ""
echo "The pre-commit hook will now:"
echo "  • Check vault-code synchronization on every commit"
echo "  • Prevent commits if vault status doesn't match code"
echo "  • Validate manual_update flags for completed items"
echo "  • Check Python code quality (if black/ruff installed)"
echo "  • Warn about large files"
echo ""
echo "To test the hook, try making a commit. If vault sync fails, run:"
echo "  make sync-status"
echo ""
echo "To bypass hooks in emergency (NOT RECOMMENDED):"
echo "  git commit --no-verify"
echo ""
echo "For more information, see: documentation/CLAUDE.md"