#!/bin/bash

# Service Watcher - Surveillance des services critiques
# Author: Riantsoa Rajhonson
# Usage: ./service-watcher.sh -s "nginx mysql" -r

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SERVICES=""
AUTO_RESTART=false
INTERVAL=30
LOG_FILE="logs/service-watcher.log"
MAX_RESTART_ATTEMPTS=3

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Surveillance continue des services système critiques.

OPTIONS:
    -s, --services <list>     Liste des services (séparés par espace)
    -r, --restart             Auto-restart des services arrêtés
    -i, --interval <seconds>  Intervalle de vérification (défaut: 30s)
    -l, --log <file>          Fichier de log
    -h, --help                Afficher cette aide

EXEMPLES:
    $(basename "$0") -s "nginx apache2 mysql"
    $(basename "$0") -s "sshd" -r -i 60

AUTHOR:
    Riantsoa Rajhonson - NetOps Automation Toolkit
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--services) SERVICES="$2"; shift 2 ;;
        -r|--restart) AUTO_RESTART=true; shift ;;
        -i|--interval) INTERVAL="$2"; shift 2 ;;
        -l|--log) LOG_FILE="$2"; shift 2 ;;
        -h|--help) show_help; exit 0 ;;
        *) echo -e "${RED}Erreur: Option inconnue: $1${NC}"; show_help; exit 1 ;;
    esac
done

if [[ -z "$SERVICES" ]]; then
    echo -e "${RED}Erreur: Aucun service spécifié${NC}"
    show_help
    exit 1
fi

mkdir -p "$(dirname "$LOG_FILE")"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                   Service Watcher Monitor                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Services surveillés: $SERVICES"
echo "Auto-restart: $AUTO_RESTART"
echo "Interval: ${INTERVAL}s"
echo ""

# Tableau associatif pour compter les tentatives de restart
declare -A restart_attempts

check_service() {
    local service=$1
    
    if systemctl is-active --quiet "$service"; then
        echo -e "${GREEN}✓${NC} $service: Running"
        restart_attempts[$service]=0
        return 0
    else
        echo -e "${RED}✗${NC} $service: Stopped"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: $service is stopped" >> "$LOG_FILE"
        
        if [[ "$AUTO_RESTART" == true ]]; then
            local attempts=${restart_attempts[$service]:-0}
            
            if [[ $attempts -lt $MAX_RESTART_ATTEMPTS ]]; then
                echo -e "  ${YELLOW}↻ Attempting restart (attempt $((attempts + 1))/$MAX_RESTART_ATTEMPTS)...${NC}"
                
                if sudo systemctl restart "$service"; then
                    echo -e "  ${GREEN}✓ Service restarted successfully${NC}"
                    echo "$(date '+%Y-%m-%d %H:%M:%S') - INFO: $service restarted successfully" >> "$LOG_FILE"
                    restart_attempts[$service]=0
                else
                    echo -e "  ${RED}✗ Failed to restart service${NC}"
                    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: Failed to restart $service" >> "$LOG_FILE"
                    restart_attempts[$service]=$((attempts + 1))
                fi
            else
                echo -e "  ${RED}⚠ Max restart attempts reached. Manual intervention required.${NC}"
                echo "$(date '+%Y-%m-%d %H:%M:%S') - CRITICAL: $service max restart attempts reached" >> "$LOG_FILE"
            fi
        fi
        
        return 1
    fi
}

while true; do
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                   Service Watcher Monitor                  ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${YELLOW}Time: $(date '+%H:%M:%S') | Auto-restart: $AUTO_RESTART${NC}"
    echo ""
    
    all_ok=true
    for service in $SERVICES; do
        if ! check_service "$service"; then
            all_ok=false
        fi
    done
    
    echo ""
    if [[ "$all_ok" == true ]]; then
        echo -e "${GREEN}All services running normally${NC}"
    else
        echo -e "${RED}⚠ Some services require attention${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}Next check in ${INTERVAL}s | Press Ctrl+C to stop${NC}"
    sleep "$INTERVAL"
done
