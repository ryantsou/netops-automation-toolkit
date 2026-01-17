#!/bin/bash

# SSL Certificate Checker - Vérification des certificats SSL/TLS
# Author: Riantsoa Rajhonson
# Usage: ./ssl-cert-checker.sh -f <hosts_file> -d <days>

set -euo pipefail

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables par défaut
HOSTS_FILE="config/hosts.txt"
WARNING_DAYS=30
PORT=443
TIMEOUT=10
REPORT_FILE="reports/ssl-report-$(date +%Y%m%d).txt"

# Fonction d'aide
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Vérification des certificats SSL/TLS et alertes d'expiration.

OPTIONS:
    -f, --file <path>         Fichier contenant la liste des hôtes
    -d, --days <number>       Jours avant expiration pour l'alerte (défaut: 30)
    -p, --port <number>       Port SSL (défaut: 443)
    -t, --timeout <seconds>   Timeout de connexion (défaut: 10)
    -o, --output <file>       Fichier de rapport
    -h, --help                Afficher cette aide

FORMAT DU FICHIER HOSTS:
    Un hostname ou IP par ligne
    Exemple: example.com

EXEMPLES:
    $(basename "$0") -f config/hosts.txt -d 30
    $(basename "$0") -f websites.txt -d 60 -p 8443

AUTHOR:
    Riantsoa Rajhonson - NetOps Automation Toolkit
EOF
}

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file) HOSTS_FILE="$2"; shift 2 ;;
        -d|--days) WARNING_DAYS="$2"; shift 2 ;;
        -p|--port) PORT="$2"; shift 2 ;;
        -t|--timeout) TIMEOUT="$2"; shift 2 ;;
        -o|--output) REPORT_FILE="$2"; shift 2 ;;
        -h|--help) show_help; exit 0 ;;
        *) echo -e "${RED}Erreur: Option inconnue: $1${NC}"; show_help; exit 1 ;;
    esac
done

# Vérifier que le fichier existe
if [[ ! -f "$HOSTS_FILE" ]]; then
    echo -e "${RED}Erreur: Fichier $HOSTS_FILE introuvable${NC}"
    exit 1
fi

# Créer le répertoire de rapports
mkdir -p "$(dirname "$REPORT_FILE")"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                SSL Certificate Checker                       ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Rapport: $REPORT_FILE"
echo "Seuil d'alerte: $WARNING_DAYS jours"
echo ""

# Initialiser le rapport
{
    echo "SSL Certificate Check Report"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Warning threshold: $WARNING_DAYS days"
    echo "========================================"
    echo ""
} > "$REPORT_FILE"

# Compteurs
total=0
valid=0
expiring=0
expired=0
errors=0

# Fonction pour vérifier un certificat
check_cert() {
    local host=$1
    local port=$2
    
    echo -e "${YELLOW}Vérification: $host:$port${NC}"
    
    # Obtenir les informations du certificat
    local cert_info=$(echo | timeout $TIMEOUT openssl s_client -servername "$host" -connect "$host:$port" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null)
    
    if [[ -z "$cert_info" ]]; then
        echo -e "  ${RED}✗ Erreur de connexion ou certificat invalide${NC}"
        echo "$host:$port - ERROR: Cannot retrieve certificate" >> "$REPORT_FILE"
        ((errors++))
        return 1
    fi
    
    # Extraire la date d'expiration
    local expiry_date=$(echo "$cert_info" | grep "notAfter" | cut -d= -f2)
    local expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null)
    local current_epoch=$(date +%s)
    local days_left=$(( (expiry_epoch - current_epoch) / 86400 ))
    
    # Afficher le résultat
    if [[ $days_left -lt 0 ]]; then
        echo -e "  ${RED}✗ EXPIRÉ depuis ${days_left#-} jours${NC}"
        echo "$host:$port - EXPIRED: $expiry_date (${days_left} days ago)" >> "$REPORT_FILE"
        ((expired++))
    elif [[ $days_left -le $WARNING_DAYS ]]; then
        echo -e "  ${YELLOW}⚠ ATTENTION: Expire dans $days_left jours ($expiry_date)${NC}"
        echo "$host:$port - WARNING: Expires in $days_left days ($expiry_date)" >> "$REPORT_FILE"
        ((expiring++))
    else
        echo -e "  ${GREEN}✓ Valide: Expire dans $days_left jours ($expiry_date)${NC}"
        echo "$host:$port - OK: Expires in $days_left days ($expiry_date)" >> "$REPORT_FILE"
        ((valid++))
    fi
    
    echo ""
}

# Lire et traiter chaque hôte
while IFS= read -r host || [[ -n "$host" ]]; do
    # Ignorer les lignes vides et les commentaires
    [[ -z "$host" || "$host" =~ ^# ]] && continue
    
    ((total++))
    check_cert "$host" "$PORT"
done < "$HOSTS_FILE"

# Résumé
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                         RÉSUMÉ                                ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Total vérifié      : $total"
echo -e "${GREEN}Valides            : $valid${NC}"
echo -e "${YELLOW}Expirent bientôt   : $expiring${NC}"
echo -e "${RED}Expirés            : $expired${NC}"
echo -e "${RED}Erreurs            : $errors${NC}"
echo ""
echo "Rapport complet: $REPORT_FILE"

# Ajouter le résumé au rapport
{
    echo ""
    echo "========================================"
    echo "SUMMARY"
    echo "========================================"
    echo "Total checked: $total"
    echo "Valid: $valid"
    echo "Expiring soon: $expiring"
    echo "Expired: $expired"
    echo "Errors: $errors"
} >> "$REPORT_FILE"

# Code de sortie
if [[ $expired -gt 0 ]]; then
    exit 2
elif [[ $expiring -gt 0 ]]; then
    exit 1
else
    exit 0
fi
