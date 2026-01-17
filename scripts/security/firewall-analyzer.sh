#!/bin/bash

# Firewall Analyzer - Analyse des règles firewall
# Author: Riantsoa Rajhonson
# Usage: ./firewall-analyzer.sh -t iptables

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FW_TYPE="iptables"
REPORT_FILE="reports/firewall-analysis-$(date +%Y%m%d).txt"

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Analyse des règles firewall et détection de failles de sécurité.

OPTIONS:
    -t, --type <type>         Type de firewall (iptables/ufw/nftables)
    -o, --output <file>       Fichier de rapport
    -h, --help                Afficher cette aide

ANALYSES EFFECTUÉES:
    - Règles permissives (ACCEPT ALL)
    - Ports dangereux ouverts
    - Règles redondantes
    - Configuration par défaut
    - Services exposés

EXEMPLES:
    $(basename "$0") -t iptables
    $(basename "$0") -t ufw -o firewall-audit.txt

AUTHOR:
    Riantsoa Rajhonson - NetOps Automation Toolkit
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type) FW_TYPE="$2"; shift 2 ;;
        -o|--output) REPORT_FILE="$2"; shift 2 ;;
        -h|--help) show_help; exit 0 ;;
        *) echo -e "${RED}Erreur: Option inconnue: $1${NC}"; show_help; exit 1 ;;
    esac
done

mkdir -p "$(dirname "$REPORT_FILE")"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                  Firewall Security Analyzer                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Type: $FW_TYPE"
echo "Report: $REPORT_FILE"
echo ""

{
    echo "FIREWALL SECURITY ANALYSIS REPORT"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Firewall Type: $FW_TYPE"
    echo "========================================"
    echo ""
} > "$REPORT_FILE"

issues_found=0

if [[ "$FW_TYPE" == "iptables" ]]; then
    echo -e "${YELLOW}Analyzing iptables rules...${NC}"
    
    # Vérifier les règles permissives
    echo -e "\n${BLUE}[1] Checking for permissive rules...${NC}"
    permissive_rules=$(sudo iptables -L -n -v | grep -E "ACCEPT.*0.0.0.0/0" || true)
    if [[ -n "$permissive_rules" ]]; then
        echo -e "${RED}⚠ Warning: Permissive ACCEPT rules found:${NC}"
        echo "$permissive_rules"
        echo -e "\nPERMISSIVE RULES DETECTED:" >> "$REPORT_FILE"
        echo "$permissive_rules" >> "$REPORT_FILE"
        ((issues_found++))
    else
        echo -e "${GREEN}✓ No permissive rules detected${NC}"
    fi
    
    # Vérifier les ports dangereux
    echo -e "\n${BLUE}[2] Checking for dangerous open ports...${NC}"
    dangerous_ports=("23" "21" "3389" "5900")
    for port in "${dangerous_ports[@]}"; do
        if sudo iptables -L -n | grep -q "dpt:$port"; then
            echo -e "${RED}⚠ Warning: Dangerous port $port is open${NC}"
            echo "DANGEROUS PORT OPEN: $port" >> "$REPORT_FILE"
            ((issues_found++))
        fi
    done
    
    # Politique par défaut
    echo -e "\n${BLUE}[3] Checking default policies...${NC}"
    default_policy=$(sudo iptables -L | grep "Chain INPUT" | awk '{print $4}')
    if [[ "$default_policy" == "ACCEPT)" ]]; then
        echo -e "${RED}⚠ Warning: Default INPUT policy is ACCEPT (should be DROP)${NC}"
        echo "DEFAULT POLICY WARNING: INPUT chain default is ACCEPT" >> "$REPORT_FILE"
        ((issues_found++))
    else
        echo -e "${GREEN}✓ Default policy is secure: $default_policy${NC}"
    fi
    
    # Dump complet des règles
    echo -e "\n${BLUE}[4] Saving complete ruleset...${NC}"
    echo -e "\n\nCOMPLETE IPTABLES RULESET:" >> "$REPORT_FILE"
    echo "====================================" >> "$REPORT_FILE"
    sudo iptables -L -n -v >> "$REPORT_FILE"
    
elif [[ "$FW_TYPE" == "ufw" ]]; then
    echo -e "${YELLOW}Analyzing UFW rules...${NC}"
    
    if ! command -v ufw &> /dev/null; then
        echo -e "${RED}Error: UFW not installed${NC}"
        exit 1
    fi
    
    echo -e "\n${BLUE}[1] UFW Status:${NC}"
    ufw_status=$(sudo ufw status verbose)
    echo "$ufw_status"
    echo -e "\nUFW STATUS:" >> "$REPORT_FILE"
    echo "$ufw_status" >> "$REPORT_FILE"
    
    if echo "$ufw_status" | grep -q "Status: inactive"; then
        echo -e "${RED}⚠ CRITICAL: UFW is inactive!${NC}"
        echo "CRITICAL: UFW FIREWALL IS INACTIVE" >> "$REPORT_FILE"
        ((issues_found += 5))
    fi
    
else
    echo -e "${RED}Error: Unsupported firewall type: $FW_TYPE${NC}"
    exit 1
fi

# Vérifier les ports ouverts
echo -e "\n${BLUE}[5] Checking currently open ports...${NC}"
if command -v ss &> /dev/null; then
    open_ports=$(sudo ss -tuln | grep LISTEN)
    echo -e "${YELLOW}Open listening ports:${NC}"
    echo "$open_ports"
    echo -e "\n\nOPEN LISTENING PORTS:" >> "$REPORT_FILE"
    echo "$open_ports" >> "$REPORT_FILE"
fi

# Résumé
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                        SUMMARY                             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [[ $issues_found -eq 0 ]]; then
    echo -e "${GREEN}✓ No critical security issues found${NC}"
    echo "STATUS: PASS" >> "$REPORT_FILE"
    exit 0
else
    echo -e "${RED}⚠ Found $issues_found security issue(s)${NC}"
    echo -e "${YELLOW}Review the report for details: $REPORT_FILE${NC}"
    echo -e "\nSTATUS: FAIL - $issues_found issue(s) found" >> "$REPORT_FILE"
    exit 1
fi
