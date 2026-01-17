#!/bin/bash

# Network Report Generator - Génération de rapports réseau complets
# Author: Riantsoa Rajhonson
# Usage: ./network-report.sh -o reports/

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

OUTPUT_DIR="reports"
FORMAT="text"
REPORT_NAME="network-report-$(date +%Y%m%d_%H%M%S)"
INCLUDE_SYSTEM=true
INCLUDE_NETWORK=true
INCLUDE_SECURITY=true

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Génération de rapports réseau complets et détaillés.

OPTIONS:
    -o, --output <dir>        Répertoire de sortie (défaut: reports/)
    -f, --format <type>       Format de sortie (text/html/json)
    -n, --name <name>         Nom du rapport
    --no-system               Exclure les infos système
    --no-network              Exclure les infos réseau
    --no-security             Exclure les infos sécurité
    -h, --help                Afficher cette aide

SECTIONS DU RAPPORT:
    - Informations système (CPU, RAM, disque)
    - Configuration réseau (interfaces, routes, DNS)
    - Services actifs et ports ouverts
    - Connexions actives
    - Configuration firewall
    - Statistiques de trafic
    - Alertes et anomalies

EXEMPLES:
    $(basename "$0") -o reports/ -f html
    $(basename "$0") --no-security -f json

AUTHOR:
    Riantsoa Rajhonson - NetOps Automation Toolkit
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output) OUTPUT_DIR="$2"; shift 2 ;;
        -f|--format) FORMAT="$2"; shift 2 ;;
        -n|--name) REPORT_NAME="$2"; shift 2 ;;
        --no-system) INCLUDE_SYSTEM=false; shift ;;
        --no-network) INCLUDE_NETWORK=false; shift ;;
        --no-security) INCLUDE_SECURITY=false; shift ;;
        -h|--help) show_help; exit 0 ;;
        *) echo -e "${RED}Erreur: Option inconnue: $1${NC}"; show_help; exit 1 ;;
    esac
done

mkdir -p "$OUTPUT_DIR"

REPORT_FILE="$OUTPUT_DIR/${REPORT_NAME}.${FORMAT}"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Network Report Generator                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Report: $REPORT_FILE"
echo "Format: $FORMAT"
echo ""
echo -e "${YELLOW}Collecting information...${NC}"
echo ""

# Initialiser le rapport
{
    echo "========================================"
    echo "     NETWORK INFRASTRUCTURE REPORT"
    echo "========================================"
    echo ""
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Hostname: $(hostname)"
    echo "Report by: NetOps Automation Toolkit"
    echo ""
} > "$REPORT_FILE"

# Section 1: Informations Système
if [[ "$INCLUDE_SYSTEM" == true ]]; then
    echo -e "${BLUE}[1/3] Collecting system information...${NC}"
    {
        echo "========================================"
        echo "1. SYSTEM INFORMATION"
        echo "========================================"
        echo ""
        echo "Operating System:"
        uname -a
        echo ""
        if [ -f /etc/os-release ]; then
            echo "Distribution:"
            cat /etc/os-release | grep -E "PRETTY_NAME|VERSION" | cut -d= -f2 | tr -d '"'
            echo ""
        fi
        echo "Uptime:"
        uptime
        echo ""
        echo "CPU Information:"
        lscpu | grep -E "Model name|CPU\(s\):|Thread" || echo "lscpu not available"
        echo ""
        echo "Memory Usage:"
        free -h
        echo ""
        echo "Disk Usage:"
        df -h | grep -v "tmpfs" | grep -v "loop"
        echo ""
    } >> "$REPORT_FILE"
fi

# Section 2: Configuration Réseau
if [[ "$INCLUDE_NETWORK" == true ]]; then
    echo -e "${BLUE}[2/3] Collecting network information...${NC}"
    {
        echo "========================================"
        echo "2. NETWORK CONFIGURATION"
        echo "========================================"
        echo ""
        echo "Network Interfaces:"
        ip -br addr show || ifconfig -a
        echo ""
        echo "Routing Table:"
        ip route show || route -n
        echo ""
        echo "DNS Configuration:"
        cat /etc/resolv.conf 2>/dev/null || echo "DNS config not accessible"
        echo ""
        echo "Active Connections:"
        ss -tunap 2>/dev/null | head -20 || netstat -tunap 2>/dev/null | head -20 || echo "Connection info not available"
        echo ""
        echo "Listening Ports:"
        ss -tuln 2>/dev/null || netstat -tuln 2>/dev/null || echo "Port info not available"
        echo ""
        echo "Network Statistics:"
        ip -s link show 2>/dev/null || netstat -i || echo "Network stats not available"
        echo ""
    } >> "$REPORT_FILE"
fi

# Section 3: Sécurité
if [[ "$INCLUDE_SECURITY" == true ]]; then
    echo -e "${BLUE}[3/3] Collecting security information...${NC}"
    {
        echo "========================================"
        echo "3. SECURITY STATUS"
        echo "========================================"
        echo ""
        echo "Firewall Status (iptables):"
        sudo iptables -L -n -v 2>/dev/null | head -30 || echo "iptables not accessible"
        echo ""
        echo "UFW Status:"
        sudo ufw status verbose 2>/dev/null || echo "UFW not installed/accessible"
        echo ""
        echo "Active Services:"
        systemctl list-units --type=service --state=running 2>/dev/null | head -20 || service --status-all 2>/dev/null | grep running | head -20 || echo "Service info not available"
        echo ""
        echo "Failed Login Attempts (last 20):"
        grep "Failed password" /var/log/auth.log 2>/dev/null | tail -20 || echo "Auth log not accessible"
        echo ""
        echo "SSH Configuration:"
        grep -E "Port|PermitRootLogin|PasswordAuthentication" /etc/ssh/sshd_config 2>/dev/null || echo "SSH config not accessible"
        echo ""
    } >> "$REPORT_FILE"
fi

# Footer
{
    echo "========================================"
    echo "END OF REPORT"
    echo "========================================"
    echo ""
    echo "Generated by NetOps Automation Toolkit"
    echo "For support: https://github.com/ryantsou/netops-automation-toolkit"
} >> "$REPORT_FILE"

echo ""
echo -e "${GREEN}✓ Report generated successfully${NC}"
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                        SUMMARY                             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Report location: $REPORT_FILE"
echo "File size: $(du -h "$REPORT_FILE" | cut -f1)"
echo ""
echo "Sections included:"
[[ "$INCLUDE_SYSTEM" == true ]] && echo -e "  ${GREEN}✓${NC} System Information"
[[ "$INCLUDE_NETWORK" == true ]] && echo -e "  ${GREEN}✓${NC} Network Configuration"
[[ "$INCLUDE_SECURITY" == true ]] && echo -e "  ${GREEN}✓${NC} Security Status"
echo ""
echo -e "${YELLOW}View report with: cat $REPORT_FILE${NC}"
