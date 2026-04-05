#!/bin/bash

# NetOps Automation Toolkit - Installation Script
# Author: Riantsoa Rajhonson
# Description: Automated toolkit installation

set -euo pipefail

COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_RED="\033[0;31m"
COLOR_RESET="\033[0m"

echo -e "${COLOR_GREEN}╔═══════════════════════════════════════════╗${COLOR_RESET}"
echo -e "${COLOR_GREEN}║  NetOps Automation Toolkit - Installer  ║${COLOR_RESET}"
echo -e "${COLOR_GREEN}╚═══════════════════════════════════════════╝${COLOR_RESET}"
echo ""

# Check prerequisites
echo -e "${COLOR_YELLOW}[1/5]${COLOR_RESET} Checking prerequisites..."

check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "  ✓ $1 installed"
    else
        echo -e "  ${COLOR_RED}✗ $1 missing${COLOR_RESET}"
        MISSING_DEPS="$MISSING_DEPS $1"
    fi
}

MISSING_DEPS=""
check_command bash
check_command curl
check_command wget
check_command ping
check_command ip
check_command nslookup
check_command netstat
check_command bc
check_command openssl
check_command timeout

if [ ! -z "$MISSING_DEPS" ]; then
    echo -e "${COLOR_RED}Error: Missing dependencies:$MISSING_DEPS${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Install them with: sudo apt-get install$MISSING_DEPS${COLOR_RESET}"
    exit 1
fi

# Create directories
echo -e "${COLOR_YELLOW}[2/5]${COLOR_RESET} Creating directory structure..."
mkdir -p config/templates
mkdir -p logs
mkdir -p reports
mkdir -p tests
mkdir -p docs
echo -e "  ✓ Directories created"

# Set permissions
echo -e "${COLOR_YELLOW}[3/5]${COLOR_RESET} Configuring permissions..."
find scripts -type f -name "*.sh" -exec chmod +x {} \;
echo -e "  ✓ Permissions configured"

# Create default configuration files
echo -e "${COLOR_YELLOW}[4/5]${COLOR_RESET} Creating configuration files..."

if [ ! -f config/hosts.txt ]; then
    cat > config/hosts.txt <<EOF
# List of hosts to monitor
# Format: IP or hostname (one per line)
8.8.8.8
1.1.1.1
EOF
    echo -e "  ✓ config/hosts.txt created"
fi

if [ ! -f config/alerts.conf ]; then
    cat > config/alerts.conf <<EOF
# Alert configuration
EMAIL_ALERT=false
EMAIL_TO="admin@example.com"
SLACK_WEBHOOK=""
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEM=85
ALERT_THRESHOLD_DISK=90
EOF
    echo -e "  ✓ config/alerts.conf created"
fi

# Add to PATH (optional)
echo -e "${COLOR_YELLOW}[5/5]${COLOR_RESET} Configuring PATH (optional)..."
echo ""
echo -e "${COLOR_YELLOW}Do you want to add scripts to PATH? (y/n)${COLOR_RESET}"
read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    TOOLKIT_PATH=$(pwd)
    SHELL_RC="$HOME/.bashrc"
    
    if [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_RC="$HOME/.zshrc"
    fi
    
    if ! grep -q "netops-automation-toolkit" "$SHELL_RC"; then
        echo "" >> "$SHELL_RC"
        echo "# NetOps Automation Toolkit" >> "$SHELL_RC"
        echo "export PATH=\"\$PATH:$TOOLKIT_PATH/scripts/monitoring\"" >> "$SHELL_RC"
        echo "export PATH=\"\$PATH:$TOOLKIT_PATH/scripts/security\"" >> "$SHELL_RC"
        echo "export PATH=\"\$PATH:$TOOLKIT_PATH/scripts/automation\"" >> "$SHELL_RC"
        echo "export PATH=\"\$PATH:$TOOLKIT_PATH/scripts/reporting\"" >> "$SHELL_RC"
        echo -e "  ✓ PATH added to $SHELL_RC"
        echo -e "  ${COLOR_YELLOW}Run: source $SHELL_RC${COLOR_RESET}"
    else
        echo -e "  ${COLOR_YELLOW}PATH already configured${COLOR_RESET}"
    fi
else
    echo -e "  ⊗ PATH not modified"
fi

echo ""
echo -e "${COLOR_GREEN}╔═══════════════════════════════════════════╗${COLOR_RESET}"
echo -e "${COLOR_GREEN}║     Installation completed successfully!   ║${COLOR_RESET}"
echo -e "${COLOR_GREEN}╚═══════════════════════════════════════════╝${COLOR_RESET}"
echo ""
echo -e "${COLOR_YELLOW}Next steps:${COLOR_RESET}"
echo "  1. Edit configuration files in config/"
echo "  2. Test a script: ./scripts/monitoring/bandwidth-monitor.sh --help"
echo "  3. Read documentation: cat README.md"
echo ""
echo -e "${COLOR_GREEN}Happy networking! 🚀${COLOR_RESET}"
