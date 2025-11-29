#!/bin/bash
# install.sh - Remote installer for Git-Core Protocol
# Usage: curl -sL https://raw.githubusercontent.com/iberi22/ai-git-core-template/main/install.sh | bash
#
# 🎯 This script can be executed by AI agents to bootstrap any project with Git-Core Protocol
# Options:
#   --organize, -o    Organize existing files before installing
#   --auto, -y        Non-interactive mode (auto-accept)
#   --upgrade, -u     Upgrade existing installation (overwrite protocol files)

set -e

REPO_URL="https://github.com/iberi22/ai-git-core-template"
TEMP_DIR=".git-core-temp"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🧠 Git-Core Protocol - Remote Installer${NC}"
echo "========================================"
echo ""

# Parse arguments
ORGANIZE_FILES=false
AUTO_MODE=false
UPGRADE_MODE=false
for arg in "$@"; do
    case $arg in
        --organize|-o)
            ORGANIZE_FILES=true
            ;;
        --auto|-y)
            AUTO_MODE=true
            ;;
        --upgrade|-u)
            UPGRADE_MODE=true
            AUTO_MODE=true  # Upgrade implies auto
            ;;
    esac
done

# Show upgrade mode
if [ "$UPGRADE_MODE" = true ]; then
    echo -e "${YELLOW}🔄 UPGRADE MODE: Protocol files will be overwritten${NC}"
    echo ""
fi

# Function to organize existing files
organize_existing_files() {
    echo -e "${YELLOW}📂 Organizing existing files...${NC}"

    # Create necessary directories
    mkdir -p docs/archive scripts tests src

    # Move markdown files to docs/archive (except special ones)
    for file in *.md; do
        if [ -f "$file" ]; then
            case "$file" in
                README.md|AGENTS.md|CHANGELOG.md|CONTRIBUTING.md|LICENSE.md)
                    echo -e "  ${GREEN}✓ Keeping $file in root${NC}"
                    ;;
                *)
                    mv "$file" "docs/archive/" 2>/dev/null && \
                    echo -e "  ${CYAN}→ $file moved to docs/archive/${NC}" || true
                    ;;
            esac
        fi
    done

    # Move test files
    for pattern in test_*.py *_test.py *_test.js *.test.js *.test.ts test_*.js *.spec.js *.spec.ts; do
        for file in $pattern; do
            if [ -f "$file" ] && [ "$file" != "$pattern" ]; then
                mv "$file" "tests/" 2>/dev/null && \
                echo -e "  ${CYAN}→ $file moved to tests/${NC}" || true
            fi
        done
    done

    # Move loose script files to scripts/ (except install.sh)
    for file in *.sh *.ps1 *.bat; do
        if [ -f "$file" ] && [ "$file" != "$pattern" ]; then
            case "$file" in
                install.sh)
                    echo -e "  ${GREEN}✓ Keeping $file in root${NC}"
                    ;;
                *)
                    mv "$file" "scripts/" 2>/dev/null && \
                    echo -e "  ${CYAN}→ $file moved to scripts/${NC}" || true
                    ;;
            esac
        fi
    done

    echo -e "${GREEN}✅ Files organized${NC}"
}

# Check if we should auto-organize
if [ "$ORGANIZE_FILES" = true ]; then
    organize_existing_files
fi

# Check if current directory has files
if [ "$(ls -A 2>/dev/null | grep -v '^\.' | head -1)" ] && [ "$AUTO_MODE" = false ]; then
    echo -e "${YELLOW}⚠️  Current directory is not empty.${NC}"
    echo ""
    echo "Options:"
    echo "  1) Continue and merge files"
    echo "  2) Organize existing files first (move .md to docs/archive/)"
    echo "  3) Cancel"
    echo ""
    read -p "Select (1/2/3): " CHOICE

    case $CHOICE in
        1)
            echo "Continuing..."
            ;;
        2)
            organize_existing_files
            ;;
        3)
            echo "Cancelled."
            exit 0
            ;;
        *)
            echo "Invalid option. Cancelling."
            exit 1
            ;;
    esac
fi

# Download template
echo -e "\n${CYAN}📥 Downloading Git-Core Protocol template...${NC}"
git clone --depth 1 "$REPO_URL" "$TEMP_DIR" 2>/dev/null || {
    echo -e "${RED}❌ Error cloning repository${NC}"
    exit 1
}

# Remove template's git history
rm -rf "$TEMP_DIR/.git"

# Move template files (don't overwrite existing)
echo -e "${CYAN}📦 Installing protocol files...${NC}"

# Copy directories
for dir in .ai .github scripts; do
    if [ -d "$TEMP_DIR/$dir" ]; then
        if [ "$UPGRADE_MODE" = true ]; then
            cp -rf "$TEMP_DIR/$dir" .
            echo -e "  ${GREEN}✓ $dir/ (upgraded)${NC}"
        else
            cp -rn "$TEMP_DIR/$dir" . 2>/dev/null || cp -r "$TEMP_DIR/$dir" .
            echo -e "  ${GREEN}✓ $dir/${NC}"
        fi
    fi
done

# Protocol files (always overwrite in upgrade mode)
PROTOCOL_FILES=".cursorrules .windsurfrules AGENTS.md .git-core-protocol-version"

for file in $PROTOCOL_FILES; do
    if [ -f "$TEMP_DIR/$file" ]; then
        if [ "$UPGRADE_MODE" = true ]; then
            cp "$TEMP_DIR/$file" .
            echo -e "  ${GREEN}✓ $file (upgraded)${NC}"
        elif [ ! -f "$file" ]; then
            cp "$TEMP_DIR/$file" .
            echo -e "  ${GREEN}✓ $file${NC}"
        else
            echo -e "  ${YELLOW}~ $file (exists, not overwritten)${NC}"
        fi
    fi
done

# .gitignore - never overwrite (project-specific)
if [ -f "$TEMP_DIR/.gitignore" ] && [ ! -f ".gitignore" ]; then
    cp "$TEMP_DIR/.gitignore" .
    echo -e "  ${GREEN}✓ .gitignore${NC}"
elif [ -f ".gitignore" ]; then
    echo -e "  ${YELLOW}~ .gitignore (exists, not overwritten)${NC}"
fi

# Copy README only if it doesn't exist
if [ ! -f "README.md" ]; then
    cp "$TEMP_DIR/README.md" .
    echo -e "  ${GREEN}✓ README.md${NC}"
else
    echo -e "  ${YELLOW}~ README.md (exists, not overwritten)${NC}"
fi

# Cleanup temp
rm -rf "$TEMP_DIR"

# Make scripts executable
chmod +x scripts/*.sh 2>/dev/null || true

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Git-Core Protocol installed${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "📋 Files installed:"
echo "   .ai/ARCHITECTURE.md    - Document your architecture here"
echo "   .github/               - Copilot rules + workflows + templates"
echo "   scripts/               - Init and update scripts"
echo "   AGENTS.md              - Rules for all AI agents"
echo "   .cursorrules           - Rules for Cursor"
echo "   .windsurfrules         - Rules for Windsurf"
echo "   .git-core-protocol-version - Protocol version (for auto-updates)"
echo ""
echo -e "${YELLOW}🚀 Next step:${NC}"
echo "   ./scripts/init_project.sh"
echo ""
echo -e "${CYAN}🔄 To check for updates later:${NC}"
echo "   ./scripts/check-protocol-update.sh --update"
echo ""
echo -e "${CYAN}💡 Tips:${NC}"
echo -e "${CYAN}   New install:  curl -sL .../install.sh | bash -s -- --auto --organize${NC}"
echo -e "${CYAN}   Upgrade:      curl -sL .../install.sh | bash -s -- --upgrade${NC}"
