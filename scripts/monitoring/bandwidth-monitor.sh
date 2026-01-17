#!/bin/bash

# Bandwidth Monitor - Surveillance de la bande passante en temps réel
# Author: Riantsoa Rajhonson
# Usage: ./bandwidth-monitor.sh -i <interface> -t <interval>

set -euo pipefail

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables par défaut
INTERFACE="eth0"
INTERVAL=5
LOG_FILE="logs/bandwidth.log"
ALERT_THRESHOLD=80 # Pourcentage

# Fonction d'aide
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Surveillance de la bande passante réseau en temps réel.

OPTIONS:
    -i, --interface <name>    Interface réseau à monitorer (défaut: eth0)
    -t, --interval <seconds>  Intervalle de rafraîchissement (défaut: 5s)
    -l, --log <file>          Fichier de log (défaut: logs/bandwidth.log)
    -a, --alert <percent>     Seuil d'alerte en % (défaut: 80)
    -h, --help                Afficher cette aide

EXEMPLES:
    $(basename "$0") -i eth0 -t 10
    $(basename "$0") -i wlan0 -t 5 -a 90

AUTHOR:
    Riantsoa Rajhonson - NetOps Automation Toolkit
EOF
}

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--interface)
            INTERFACE="$2"
            shift 2
            ;;
        -t|--interval)
            INTERVAL="$2"
            shift 2
            ;;
        -l|--log)
            LOG_FILE="$2"
            shift 2
            ;;
        -a|--alert)
            ALERT_THRESHOLD="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Erreur: Option inconnue: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Vérifier que l'interface existe
if ! ip link show "$INTERFACE" &> /dev/null; then
    echo -e "${RED}Erreur: Interface $INTERFACE introuvable${NC}"
    echo -e "${YELLOW}Interfaces disponibles:${NC}"
    ip -br link show | awk '{print "  - " $1}'
    exit 1
fi

# Créer le répertoire de logs si nécessaire
mkdir -p "$(dirname "$LOG_FILE")"

# Fonction pour obtenir les statistiques réseau
get_stats() {
    local interface=$1
    local rx_bytes=$(cat /sys/class/net/$interface/statistics/rx_bytes 2>/dev/null || echo 0)
    local tx_bytes=$(cat /sys/class/net/$interface/statistics/tx_bytes 2>/dev/null || echo 0)
    echo "$rx_bytes $tx_bytes"
}

# Fonction pour formater les bytes
format_bytes() {
    local bytes=$1
    if (( bytes > 1073741824 )); then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1073741824}") GB/s"
    elif (( bytes > 1048576 )); then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1048576}") MB/s"
    elif (( bytes > 1024 )); then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1024}") KB/s"
    else
        echo "$bytes B/s"
    fi
}

# Fonction pour afficher une barre de progression
show_bar() {
    local percent=$1
    local width=50
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    
    printf "["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %3d%%" "$percent"
}

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Bandwidth Monitor - Interface: $INTERFACE          ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo -e "${YELLOW}Intervalle: ${INTERVAL}s | Seuil d'alerte: ${ALERT_THRESHOLD}%${NC}"
echo -e "${YELLOW}Appuyez sur Ctrl+C pour arrêter${NC}"
echo ""

# Obtenir les statistiques initiales
read rx_prev tx_prev <<< $(get_stats "$INTERFACE")
sleep 1

# Boucle principale
while true; do
    # Obtenir les nouvelles statistiques
    read rx_curr tx_curr <<< $(get_stats "$INTERFACE")
    
    # Calculer les débits
    rx_rate=$(( (rx_curr - rx_prev) / INTERVAL ))
    tx_rate=$(( (tx_curr - tx_prev) / INTERVAL ))
    
    # Sauvegarder les valeurs actuelles
    rx_prev=$rx_curr
    tx_prev=$tx_curr
    
    # Obtenir la capacité max de l'interface (en supposant 1 Gbps)
    max_bandwidth=125000000 # 1 Gbps = 125 MB/s
    
    # Calculer les pourcentages
    rx_percent=$(( rx_rate * 100 / max_bandwidth ))
    tx_percent=$(( tx_rate * 100 / max_bandwidth ))
    
    # Limiter à 100%
    [[ $rx_percent -gt 100 ]] && rx_percent=100
    [[ $tx_percent -gt 100 ]] && tx_percent=100
    
    # Affichage
    clear
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           Bandwidth Monitor - Interface: $INTERFACE          ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}⬇ Download (RX):${NC}"
    echo -n "  "
    show_bar $rx_percent
    echo " - $(format_bytes $rx_rate)"
    echo ""
    echo -e "${YELLOW}⬆ Upload (TX):${NC}"
    echo -n "  "
    show_bar $tx_percent
    echo " - $(format_bytes $tx_rate)"
    echo ""
    echo -e "${BLUE}Total:${NC}"
    echo "  RX Total: $(format_bytes $rx_curr) | TX Total: $(format_bytes $tx_curr)"
    echo ""
    
    # Alertes
    if [[ $rx_percent -ge $ALERT_THRESHOLD ]] || [[ $tx_percent -ge $ALERT_THRESHOLD ]]; then
        echo -e "${RED}⚠ ALERTE: Utilisation élevée de la bande passante!${NC}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ALERT: RX=$rx_percent% TX=$tx_percent%" >> "$LOG_FILE"
    fi
    
    echo -e "${YELLOW}Dernière mise à jour: $(date '+%H:%M:%S')${NC}"
    echo -e "${YELLOW}Appuyez sur Ctrl+C pour arrêter${NC}"
    
    # Logger les données
    echo "$(date '+%Y-%m-%d %H:%M:%S'),$rx_rate,$tx_rate,$rx_percent,$tx_percent" >> "$LOG_FILE"
    
    sleep "$INTERVAL"
done
