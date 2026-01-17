#!/bin/bash

# Bulk Ping - Test de connectivité massif
# Author: Riantsoa Rajhonson
# Usage: ./bulk-ping.sh -r 192.168.1.0/24

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

RANGE=""
FILE=""
COUNT=1
TIMEOUT=1
THREADS=50
REPORT_FILE="reports/bulk-ping-$(date +%Y%m%d_%H%M%S).txt"

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Test de connectivité massif sur plages IP ou liste d'hôtes.

OPTIONS:
    -r, --range <cidr>        Plage IP en notation CIDR (ex: 192.168.1.0/24)
    -f, --file <path>         Fichier contenant liste d'IPs/hostnames
    -c, --count <number>      Nombre de pings par hôte (défaut: 1)
    -t, --timeout <seconds>   Timeout par ping (défaut: 1s)
    -j, --threads <number>    Nombre de threads parallèles (défaut: 50)
    -o, --output <file>       Fichier de rapport
    -h, --help                Afficher cette aide

EXEMPLES:
    $(basename "$0") -r 192.168.1.0/24
    $(basename "$0") -f hosts.txt -c 3 -t 2
    $(basename "$0") -r 10.0.0.0/16 -j 100

OUTPUT:
    - Liste des hôtes accessibles
    - Liste des hôtes inaccessibles
    - Statistiques de disponibilité
    - Temps de réponse moyens

AUTHOR:
    Riantsoa Rajhonson - NetOps Automation Toolkit
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--range) RANGE="$2"; shift 2 ;;
        -f|--file) FILE="$2"; shift 2 ;;
        -c|--count) COUNT="$2"; shift 2 ;;
        -t|--timeout) TIMEOUT="$2"; shift 2 ;;
        -j|--threads) THREADS="$2"; shift 2 ;;
        -o|--output) REPORT_FILE="$2"; shift 2 ;;
        -h|--help) show_help; exit 0 ;;
        *) echo -e "${RED}Erreur: Option inconnue: $1${NC}"; show_help; exit 1 ;;
    esac
done

if [[ -z "$RANGE" && -z "$FILE" ]]; then
    echo -e "${RED}Erreur: Spécifiez une plage IP (-r) ou un fichier (-f)${NC}"
    show_help
    exit 1
fi

mkdir -p "$(dirname "$REPORT_FILE")"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                 Bulk Ping - Network Scanner              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Générer la liste des IPs
if [[ -n "$RANGE" ]]; then
    echo -e "${YELLOW}Generating IP list from CIDR: $RANGE${NC}"
    
    # Fonction simple pour générer les IPs d'un CIDR
    # Pour un outil de production, utiliser nmap ou ipcalc
    IFS='/' read -r base_ip prefix <<< "$RANGE"
    IFS='.' read -r i1 i2 i3 i4 <<< "$base_ip"
    
    # Simplification: supporter uniquement /24 pour cet exemple
    if [[ "$prefix" -eq 24 ]]; then
        ip_list=()
        for i in {1..254}; do
            ip_list+=("$i1.$i2.$i3.$i")
        done
    else
        echo -e "${RED}Error: Only /24 CIDR supported in this example${NC}"
        echo -e "${YELLOW}Use nmap or ipcalc for other ranges${NC}"
        exit 1
    fi
    
elif [[ -n "$FILE" ]]; then
    if [[ ! -f "$FILE" ]]; then
        echo -e "${RED}Erreur: Fichier $FILE introuvable${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Loading hosts from file: $FILE${NC}"
    mapfile -t ip_list < "$FILE"
fi

total_hosts=${#ip_list[@]}
echo -e "${BLUE}Total hosts to scan: $total_hosts${NC}"
echo -e "${YELLOW}Threads: $THREADS | Timeout: ${TIMEOUT}s${NC}"
echo ""

# Initialiser les compteurs
alive_count=0
dead_count=0

# Fichiers temporaires
alive_file="/tmp/bulk-ping-alive-$$.txt"
dead_file="/tmp/bulk-ping-dead-$$.txt"

# Fonction de ping
ping_host() {
    local ip=$1
    
    if ping -c "$COUNT" -W "$TIMEOUT" "$ip" &>/dev/null; then
        # Récupérer le temps de réponse
        local rtt=$(ping -c 1 -W 1 "$ip" 2>/dev/null | grep "time=" | awk -F'time=' '{print $2}' | awk '{print $1}')
        echo "$ip - ${rtt}ms" >> "$alive_file"
        echo -ne "${GREEN}.${NC}"
    else
        echo "$ip" >> "$dead_file"
        echo -ne "${RED}x${NC}"
    fi
}

export -f ping_host
export COUNT TIMEOUT alive_file dead_file GREEN RED NC

echo -e "${YELLOW}Scanning in progress...${NC}"
echo ""

# Lancer les pings en parallèle
printf '%s\n' "${ip_list[@]}" | xargs -P "$THREADS" -I {} bash -c 'ping_host "$@"' _ {}

echo ""
echo ""

# Compter les résultats
if [[ -f "$alive_file" ]]; then
    alive_count=$(wc -l < "$alive_file")
fi

if [[ -f "$dead_file" ]]; then
    dead_count=$(wc -l < "$dead_file")
fi

# Générer le rapport
{
    echo "BULK PING REPORT"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "========================================"
    echo ""
    echo "SUMMARY:"
    echo "Total hosts scanned: $total_hosts"
    echo "Alive: $alive_count"
    echo "Dead: $dead_count"
    echo "Availability: $(awk "BEGIN {printf \"%.2f\", ($alive_count/$total_hosts)*100}")%"
    echo ""
    echo "========================================"
    echo "ALIVE HOSTS:"
    echo "========================================"
    if [[ -f "$alive_file" ]]; then
        cat "$alive_file"
    fi
    echo ""
    echo "========================================"
    echo "DEAD HOSTS:"
    echo "========================================"
    if [[ -f "$dead_file" ]]; then
        cat "$dead_file"
    fi
} > "$REPORT_FILE"

# Affichage console
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                        SUMMARY                             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Total hosts scanned: $total_hosts"
echo -e "${GREEN}Alive hosts: $alive_count${NC}"
echo -e "${RED}Dead hosts: $dead_count${NC}"
avail=$(awk "BEGIN {printf \"%.2f\", ($alive_count/$total_hosts)*100}")
echo -e "${BLUE}Network availability: ${avail}%${NC}"
echo ""
echo "Full report: $REPORT_FILE"

# Nettoyage
rm -f "$alive_file" "$dead_file"

if [[ $alive_count -eq $total_hosts ]]; then
    echo -e "${GREEN}✓ All hosts are reachable${NC}"
    exit 0
elif [[ $alive_count -gt 0 ]]; then
    echo -e "${YELLOW}⚠ Some hosts are unreachable${NC}"
    exit 1
else
    echo -e "${RED}✗ No hosts are reachable${NC}"
    exit 2
fi
