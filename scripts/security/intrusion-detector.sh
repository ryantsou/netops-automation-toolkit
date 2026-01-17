#!/bin/bash

# Intrusion Detector - Détection d'intrusions et d'anomalies
# Author: Riantsoa Rajhonson
# Usage: ./intrusion-detector.sh -l /var/log/auth.log

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

LOG_FILE="/var/log/auth.log"
ALERT_FILE="logs/intrusion-alerts.log"
MAX_FAILED_ATTEMPTS=5
TIME_WINDOW=300 # 5 minutes

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Détection d'intrusions et d'activités suspectes.

OPTIONS:
    -l, --log <file>          Fichier log à analyser (défaut: /var/log/auth.log)
    -a, --alert <file>        Fichier d'alertes
    -m, --max-attempts <n>    Tentatives échouées max (défaut: 5)
    -t, --time-window <sec>   Fenêtre de temps en secondes (défaut: 300)
    -h, --help                Afficher cette aide

DÉTECTIONS:
    - Tentatives de connexion SSH échouées
    - Scans de ports
    - Escalade de privilèges
    - Connexions depuis IPs suspectes
    - Activités inhabituelles

EXEMPLES:
    $(basename "$0") -l /var/log/auth.log
    $(basename "$0") -l /var/log/secure -m 3 -t 180

AUTHOR:
    Riantsoa Rajhonson - NetOps Automation Toolkit
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--log) LOG_FILE="$2"; shift 2 ;;
        -a|--alert) ALERT_FILE="$2"; shift 2 ;;
        -m|--max-attempts) MAX_FAILED_ATTEMPTS="$2"; shift 2 ;;
        -t|--time-window) TIME_WINDOW="$2"; shift 2 ;;
        -h|--help) show_help; exit 0 ;;
        *) echo -e "${RED}Erreur: Option inconnue: $1${NC}"; show_help; exit 1 ;;
    esac
done

if [[ ! -f "$LOG_FILE" ]]; then
    echo -e "${RED}Erreur: Fichier log $LOG_FILE introuvable${NC}"
    exit 1
fi

mkdir -p "$(dirname "$ALERT_FILE")"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║               Intrusion Detection System                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Analyzing: $LOG_FILE"
echo "Alert file: $ALERT_FILE"
echo ""

threats_found=0

# 1. Détecter les tentatives SSH échouées
echo -e "${YELLOW}[1] Analyzing failed SSH login attempts...${NC}"
failed_ssh=$(grep "Failed password" "$LOG_FILE" 2>/dev/null | tail -n 100 || true)

if [[ -n "$failed_ssh" ]]; then
    # Compter les tentatives par IP
    declare -A ip_attempts
    while read -r line; do
        ip=$(echo "$line" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
        if [[ -n "$ip" ]]; then
            ip_attempts[$ip]=$((${ip_attempts[$ip]:-0} + 1))
        fi
    done <<< "$failed_ssh"
    
    for ip in "${!ip_attempts[@]}"; do
        count=${ip_attempts[$ip]}
        if [[ $count -ge $MAX_FAILED_ATTEMPTS ]]; then
            echo -e "${RED}⚠ ALERT: $count failed SSH attempts from $ip${NC}"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - HIGH: $count failed SSH attempts from $ip" >> "$ALERT_FILE"
            ((threats_found++))
        fi
    done
fi

# 2. Détecter les connexions root réussies
echo -e "\n${YELLOW}[2] Checking for root login attempts...${NC}"
root_logins=$(grep "Accepted.*root" "$LOG_FILE" 2>/dev/null | tail -n 20 || true)

if [[ -n "$root_logins" ]]; then
    echo -e "${YELLOW}⚠ Warning: Root login detected:${NC}"
    echo "$root_logins" | tail -5
    echo "$(date '+%Y-%m-%d %H:%M:%S') - MEDIUM: Root login detected" >> "$ALERT_FILE"
    ((threats_found++))
fi

# 3. Détecter les commandes sudo suspectes
echo -e "\n${YELLOW}[3] Analyzing sudo command usage...${NC}"
sudo_commands=$(grep "sudo:" "$LOG_FILE" 2>/dev/null | grep "COMMAND=" | tail -n 50 || true)

suspicious_sudo=("rm -rf" "chmod 777" "/etc/shadow" "/etc/passwd" "iptables -F")
for cmd in "${suspicious_sudo[@]}"; do
    if echo "$sudo_commands" | grep -q "$cmd"; then
        echo -e "${RED}⚠ ALERT: Suspicious sudo command detected: $cmd${NC}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - HIGH: Suspicious sudo command: $cmd" >> "$ALERT_FILE"
        ((threats_found++))
    fi
done

# 4. Détecter les connexions depuis des IPs inhabituelles
echo -e "\n${YELLOW}[4] Detecting unusual connection sources...${NC}"
recent_ips=$(grep "Accepted" "$LOG_FILE" 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u || true)

if [[ -n "$recent_ips" ]]; then
    echo -e "${BLUE}Recent connection IPs:${NC}"
    echo "$recent_ips" | head -10
fi

# 5. Vérifier les modifications de fichiers système critiques
echo -e "\n${YELLOW}[5] Checking system file modifications...${NC}"
critical_files=("/etc/passwd" "/etc/shadow" "/etc/sudoers" "/etc/ssh/sshd_config")

for file in "${critical_files[@]}"; do
    if [[ -f "$file" ]]; then
        mod_time=$(stat -c %Y "$file" 2>/dev/null || echo 0)
        current_time=$(date +%s)
        age=$((current_time - mod_time))
        
        if [[ $age -lt 86400 ]]; then # Modifié dans les dernières 24h
            echo -e "${YELLOW}⚠ Warning: $file was modified recently ($(date -d @$mod_time '+%Y-%m-%d %H:%M'))${NC}"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - MEDIUM: Critical file modified: $file" >> "$ALERT_FILE"
            ((threats_found++))
        fi
    fi
done

# Résumé
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                        SUMMARY                             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [[ $threats_found -eq 0 ]]; then
    echo -e "${GREEN}✓ No threats detected${NC}"
    exit 0
else
    echo -e "${RED}⚠ $threats_found potential threat(s) detected${NC}"
    echo -e "${YELLOW}Check alert log: $ALERT_FILE${NC}"
    exit 1
fi
