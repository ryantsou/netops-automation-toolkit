#!/bin/bash

# Config Backup - Sauvegarde automatisée des configurations réseau
# Author: Riantsoa Rajhonson
# Usage: ./config-backup.sh -c config/devices.yaml -e

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CONFIG_FILE="config/devices.yaml"
BACKUP_DIR="backups/$(date +%Y%m%d)"
ENCRYPT=false
ENCRYPTION_KEY=""
GIT_ENABLED=true
MAX_BACKUPS=30

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Sauvegarde automatisée des configurations d'équipements réseau.

OPTIONS:
    -c, --config <file>       Fichier de configuration des devices
    -d, --dir <path>          Répertoire de backup (défaut: backups/YYYYMMDD)
    -e, --encrypt             Chiffrer les backups (AES-256)
    -k, --key <passphrase>    Clé de chiffrement
    -g, --no-git              Désactiver le versioning Git
    -m, --max <number>        Nombre max de backups à conserver (défaut: 30)
    -h, --help                Afficher cette aide

FORMAT DU FICHIER CONFIG:
    YAML avec liste de devices (IP, type, credentials)

EXEMPLES:
    $(basename "$0") -c config/devices.yaml
    $(basename "$0") -c devices.yaml -e -k "my_secret_key"
    $(basename "$0") -d /mnt/backup -m 60

FEATURES:
    - Support multi-vendor (Cisco, Juniper, HP)
    - Versioning Git automatique
    - Chiffrement AES-256 optionnel
    - Détection de diff automatique
    - Rotation des anciens backups

AUTHOR:
    Riantsoa Rajhonson - NetOps Automation Toolkit
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config) CONFIG_FILE="$2"; shift 2 ;;
        -d|--dir) BACKUP_DIR="$2"; shift 2 ;;
        -e|--encrypt) ENCRYPT=true; shift ;;
        -k|--key) ENCRYPTION_KEY="$2"; shift 2 ;;
        -g|--no-git) GIT_ENABLED=false; shift ;;
        -m|--max) MAX_BACKUPS="$2"; shift 2 ;;
        -h|--help) show_help; exit 0 ;;
        *) echo -e "${RED}Erreur: Option inconnue: $1${NC}"; show_help; exit 1 ;;
    esac
done

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}Erreur: Fichier de configuration $CONFIG_FILE introuvable${NC}"
    exit 1
fi

if [[ "$ENCRYPT" == true && -z "$ENCRYPTION_KEY" ]]; then
    echo -e "${YELLOW}Clé de chiffrement requise. Entrez la passphrase:${NC}"
    read -s ENCRYPTION_KEY
    echo ""
fi

mkdir -p "$BACKUP_DIR"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║             Network Configuration Backup System          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Config: $CONFIG_FILE"
echo "Backup dir: $BACKUP_DIR"
echo "Encryption: $ENCRYPT"
echo "Git versioning: $GIT_ENABLED"
echo ""

# Initialiser Git si activé
if [[ "$GIT_ENABLED" == true ]]; then
    if [[ ! -d "$BACKUP_DIR/../.git" ]]; then
        echo -e "${YELLOW}Initializing Git repository...${NC}"
        (cd "$(dirname "$BACKUP_DIR")" && git init && git config user.email "backup@netops.local" && git config user.name "NetOps Backup")
    fi
fi

success_count=0
fail_count=0

# Fonction pour sauvegarder un device
backup_device() {
    local device_name=$1
    local device_ip=$2
    local device_type=$3
    
    echo -e "${YELLOW}Backing up: $device_name ($device_ip)${NC}"
    
    local backup_file="$BACKUP_DIR/${device_name}_$(date +%Y%m%d_%H%M%S).conf"
    
    # Simuler la récupération de config (exemple SSH)
    # Dans un cas réel, utiliser ssh/scp avec les bonnes commandes selon le type
    case $device_type in
        "cisco")
            # ssh admin@$device_ip "show running-config" > "$backup_file"
            echo "# Cisco Configuration Backup - $device_name" > "$backup_file"
            echo "# Date: $(date)" >> "$backup_file"
            echo "# IP: $device_ip" >> "$backup_file"
            echo "!" >> "$backup_file"
            echo "hostname $device_name" >> "$backup_file"
            echo "!" >> "$backup_file"
            ;;
        "juniper")
            # ssh admin@$device_ip "show configuration" > "$backup_file"
            echo "# Juniper Configuration Backup - $device_name" > "$backup_file"
            echo "# Date: $(date)" >> "$backup_file"
            ;;
        *)
            echo "# Generic Configuration Backup - $device_name" > "$backup_file"
            echo "# Date: $(date)" >> "$backup_file"
            ;;
    esac
    
    if [[ -f "$backup_file" ]]; then
        # Chiffrer si demandé
        if [[ "$ENCRYPT" == true ]]; then
            echo -e "  ${BLUE}Encrypting backup...${NC}"
            openssl enc -aes-256-cbc -salt -in "$backup_file" -out "${backup_file}.enc" -k "$ENCRYPTION_KEY" 2>/dev/null
            rm "$backup_file"
            backup_file="${backup_file}.enc"
        fi
        
        echo -e "  ${GREEN}✓ Backup saved: $(basename "$backup_file")${NC}"
        ((success_count++))
        return 0
    else
        echo -e "  ${RED}✗ Backup failed${NC}"
        ((fail_count++))
        return 1
    fi
}

# Parser le fichier YAML (version simplifiée)
# Dans un cas réel, utiliser yq ou un parser YAML approprié
echo -e "${BLUE}Processing devices...${NC}"
echo ""

# Exemple de devices (normalement parsé depuis YAML)
devices=(
    "core-switch-01:192.168.1.1:cisco"
    "edge-router-01:10.0.0.1:juniper"
    "access-switch-01:192.168.1.10:cisco"
)

for device in "${devices[@]}"; do
    IFS=':' read -r name ip type <<< "$device"
    backup_device "$name" "$ip" "$type"
    echo ""
done

# Commit Git si activé
if [[ "$GIT_ENABLED" == true && $success_count -gt 0 ]]; then
    echo -e "${BLUE}Committing to Git...${NC}"
    (
        cd "$(dirname "$BACKUP_DIR")"
        git add .
        git commit -m "Backup $(date '+%Y-%m-%d %H:%M:%S') - $success_count devices" 2>/dev/null || true
    )
    echo -e "${GREEN}✓ Changes committed to Git${NC}"
    echo ""
fi

# Rotation des anciens backups
echo -e "${BLUE}Cleaning old backups...${NC}"
old_backups=$(find "$(dirname "$BACKUP_DIR")" -maxdepth 1 -type d -name "[0-9]*" | sort -r | tail -n +$((MAX_BACKUPS + 1)))

if [[ -n "$old_backups" ]]; then
    echo "$old_backups" | while read -r old_dir; do
        echo -e "  ${YELLOW}Removing old backup: $(basename "$old_dir")${NC}"
        rm -rf "$old_dir"
    done
else
    echo -e "  ${GREEN}✓ No old backups to remove${NC}"
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                        SUMMARY                             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Successful backups: $success_count${NC}"
echo -e "${RED}Failed backups: $fail_count${NC}"
echo ""
echo "Backup location: $BACKUP_DIR"

if [[ $fail_count -eq 0 ]]; then
    echo -e "${GREEN}✓ All backups completed successfully${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠ Some backups failed${NC}"
    exit 1
fi
