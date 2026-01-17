#!/bin/bash

# Compliance Checker - Audit de conformité ISO 27001 / CIS Benchmarks
# Author: Riantsoa Rajhonson
# Usage: ./compliance-checker.sh -s iso27001

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

STANDARD="iso27001"
REPORT_FILE="reports/compliance-$(date +%Y%m%d_%H%M%S).txt"
VERBOSE=false

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Audit de conformité aux standards de sécurité.

OPTIONS:
    -s, --standard <type>     Standard à vérifier (iso27001/cis/pci-dss)
    -o, --output <file>       Fichier de rapport
    -v, --verbose             Mode verbeux
    -h, --help                Afficher cette aide

STANDARDS SUPPORTÉS:
    - ISO/IEC 27001:2022  : Sécurité de l'information
    - CIS Benchmarks      : Center for Internet Security
    - PCI-DSS             : Payment Card Industry (basique)

CONTRÔLES VÉRIFIÉS:
    - Configuration des mots de passe
    - Politique de firewall
    - Chiffrement
    - Logs et audit
    - Gestion des accès
    - Mises à jour de sécurité

EXEMPLES:
    $(basename "$0") -s iso27001
    $(basename "$0") -s cis -v -o audit.txt

AUTHOR:
    Riantsoa Rajhonson - NetOps Automation Toolkit
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--standard) STANDARD="$2"; shift 2 ;;
        -o|--output) REPORT_FILE="$2"; shift 2 ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -h|--help) show_help; exit 0 ;;
        *) echo -e "${RED}Erreur: Option inconnue: $1${NC}"; show_help; exit 1 ;;
    esac
done

mkdir -p "$(dirname "$REPORT_FILE")"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║            Security Compliance Checker                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Standard: $STANDARD"
echo "Report: $REPORT_FILE"
echo ""

# Initialiser le rapport
{
    echo "SECURITY COMPLIANCE AUDIT REPORT"
    echo "========================================"
    echo "Standard: $STANDARD"
    echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Hostname: $(hostname)"
    echo "========================================"
    echo ""
} > "$REPORT_FILE"

passed=0
failed=0
warnings=0

# Fonction pour exécuter un check
run_check() {
    local check_name=$1
    local check_command=$2
    local severity=$3  # pass/fail/warn
    
    echo -ne "Checking: $check_name... "
    
    if eval "$check_command" &>/dev/null; then
        echo -e "${GREEN}PASS${NC}"
        echo "[PASS] $check_name" >> "$REPORT_FILE"
        ((passed++))
    else
        if [[ "$severity" == "critical" ]]; then
            echo -e "${RED}FAIL${NC}"
            echo "[FAIL] $check_name" >> "$REPORT_FILE"
            ((failed++))
        else
            echo -e "${YELLOW}WARN${NC}"
            echo "[WARN] $check_name" >> "$REPORT_FILE"
            ((warnings++))
        fi
    fi
}

echo -e "${YELLOW}Running compliance checks...${NC}"
echo ""

if [[ "$STANDARD" == "iso27001" ]]; then
    echo -e "${BLUE}ISO/IEC 27001:2022 Controls${NC}"
    echo ""
    
    # A.5 - Politiques de sécurité
    echo -e "${BLUE}[A.5] Information Security Policies${NC}"
    run_check "Password aging policy enabled" "grep -q '^PASS_MAX_DAYS' /etc/login.defs" "critical"
    run_check "Password minimum length configured" "grep -q '^PASS_MIN_LEN' /etc/login.defs" "critical"
    
    # A.8 - Gestion des actifs
    echo -e "\n${BLUE}[A.8] Asset Management${NC}"
    run_check "System inventory available" "[ -f /etc/machine-id ]" "warn"
    run_check "Network interfaces documented" "ip link show | grep -q UP" "warn"
    
    # A.9 - Contrôle d'accès
    echo -e "\n${BLUE}[A.9] Access Control${NC}"
    run_check "Root login via SSH disabled" "grep -q '^PermitRootLogin no' /etc/ssh/sshd_config" "critical"
    run_check "Password authentication configured" "grep -q '^PasswordAuthentication' /etc/ssh/sshd_config" "warn"
    run_check "Firewall enabled" "systemctl is-active ufw || iptables -L >/dev/null 2>&1" "critical"
    
    # A.10 - Cryptographie
    echo -e "\n${BLUE}[A.10] Cryptography${NC}"
    run_check "SSH protocol 2 enforced" "grep -q '^Protocol 2' /etc/ssh/sshd_config || ! grep -q '^Protocol' /etc/ssh/sshd_config" "critical"
    run_check "Strong SSH ciphers configured" "grep -q 'Ciphers' /etc/ssh/sshd_config" "warn"
    
    # A.12 - Sécurité d'exploitation
    echo -e "\n${BLUE}[A.12] Operations Security${NC}"
    run_check "Logging service active" "systemctl is-active rsyslog || systemctl is-active syslog-ng" "critical"
    run_check "Automatic updates configured" "[ -f /etc/apt/apt.conf.d/20auto-upgrades ] || [ -f /etc/dnf/automatic.conf ]" "warn"
    run_check "Antivirus installed" "command -v clamav >/dev/null 2>&1" "warn"
    
    # A.13 - Sécurité des communications
    echo -e "\n${BLUE}[A.13] Communications Security${NC}"
    run_check "TLS/SSL available" "command -v openssl >/dev/null 2>&1" "critical"
    run_check "Secure protocols only" "! netstat -tuln 2>/dev/null | grep -E ':(21|23|80)\\s' || true" "warn"
    
elif [[ "$STANDARD" == "cis" ]]; then
    echo -e "${BLUE}CIS Benchmarks - Linux${NC}"
    echo ""
    
    # Section 1: Initial Setup
    echo -e "${BLUE}[1] Initial Setup${NC}"
    run_check "Filesystem integrity checking installed" "command -v aide >/dev/null 2>&1 || command -v tripwire >/dev/null 2>&1" "warn"
    run_check "SELinux/AppArmor enabled" "getenforce 2>/dev/null | grep -q Enforcing || aa-status >/dev/null 2>&1" "warn"
    
    # Section 4: Logging and Auditing
    echo -e "\n${BLUE}[4] Logging and Auditing${NC}"
    run_check "Auditd service active" "systemctl is-active auditd" "critical"
    run_check "Syslog service active" "systemctl is-active rsyslog || systemctl is-active syslog-ng" "critical"
    
    # Section 5: Access Control
    echo -e "\n${BLUE}[5] Access Control${NC}"
    run_check "Cron daemon enabled" "systemctl is-enabled cron || systemctl is-enabled crond" "warn"
    run_check "SSH MaxAuthTries limited" "grep -q '^MaxAuthTries [1-4]' /etc/ssh/sshd_config" "warn"
    
else
    echo -e "${RED}Error: Unsupported standard: $STANDARD${NC}"
    exit 1
fi

# Résumé
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                        SUMMARY                             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

total=$((passed + failed + warnings))
compliance_rate=$(awk "BEGIN {printf \"%.1f\", ($passed/$total)*100}")

echo -e "${GREEN}Passed: $passed${NC}"
echo -e "${RED}Failed: $failed${NC}"
echo -e "${YELLOW}Warnings: $warnings${NC}"
echo ""
echo "Total checks: $total"
echo "Compliance rate: ${compliance_rate}%"
echo ""
echo "Full report: $REPORT_FILE"

# Ajouter le résumé au rapport
{
    echo ""
    echo "========================================"
    echo "SUMMARY"
    echo "========================================"
    echo "Passed: $passed"
    echo "Failed: $failed"
    echo "Warnings: $warnings"
    echo "Total: $total"
    echo "Compliance rate: ${compliance_rate}%"
    echo ""
    echo "Status: $([ $failed -eq 0 ] && echo 'COMPLIANT' || echo 'NON-COMPLIANT')"
} >> "$REPORT_FILE"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}✓ System is compliant with $STANDARD${NC}"
    exit 0
else
    echo -e "${RED}⚠ System is NOT compliant with $STANDARD${NC}"
    echo -e "${YELLOW}Review the report and fix failed checks${NC}"
    exit 1
fi
