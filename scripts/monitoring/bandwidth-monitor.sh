#!/bin/bash

# Bandwidth Monitor - Real-time bandwidth monitoring
# Author: Riantsoa Rajhonson
# Usage: ./bandwidth-monitor.sh -i <interface> -t <interval>

set -euo pipefail

# Colors for display
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default variables
INTERFACE="eth0"
INTERVAL=5
LOG_FILE="logs/bandwidth.log"
ALERT_THRESHOLD=80 # Percentage

# Help function
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Real-time network bandwidth monitoring.

OPTIONS:
    -i, --interface <name>    Network interface to monitor (default: eth0)
    -t, --interval <seconds>  Refresh interval (default: 5s)
    -l, --log <file>          Log file (default: logs/bandwidth.log)
    -a, --alert <percent>     Alert threshold in % (default: 80)
    -h, --help                Display this help

EXAMPLES:
    $(basename "$0") -i eth0 -t 10
    $(basename "$0") -i wlan0 -t 5 -a 90

AUTHOR:
    Riantsoa Rajhonson - NetOps Automation Toolkit
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--interface) INTERFACE="$2"; shift 2 ;;
        -t|--interval) INTERVAL="$2"; shift 2 ;;
        -l|--log) LOG_FILE="$2"; shift 2 ;;
        -a|--alert) ALERT_THRESHOLD="$2"; shift 2 ;;
        -h|--help) show_help; exit 0 ;;
        *) echo -e "${RED}Error: Unknown option: $1${NC}"; show_help; exit 1 ;;
    esac
done

# Check if interface exists
if ! ip link show "$INTERFACE" &> /dev/null; then
    echo -e "${RED}Error: Interface $INTERFACE not found${NC}"
    echo -e "${YELLOW}Available interfaces:${NC}"
    ip -br link show | awk '{print "  - " $1}'
    exit 1
fi

# Create log directory if needed
mkdir -p "$(dirname "$LOG_FILE")"

# Function to get network statistics
get_stats() {
    local interface=$1
    local rx_bytes=$(cat /sys/class/net/$interface/statistics/rx_bytes 2>/dev/null || echo 0)
    local tx_bytes=$(cat /sys/class/net/$interface/statistics/tx_bytes 2>/dev/null || echo 0)
    echo "$rx_bytes $tx_bytes"
}

# Function to format bytes
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

# Function to display progress bar
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
echo -e "${YELLOW}Interval: ${INTERVAL}s | Alert threshold: ${ALERT_THRESHOLD}%${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
echo ""

# Get initial statistics
read rx_prev tx_prev <<< $(get_stats "$INTERFACE")
sleep 1

# Main loop
while true; do
    # Get new statistics
    read rx_curr tx_curr <<< $(get_stats "$INTERFACE")
    
    # Calculate rates
    rx_rate=$(( (rx_curr - rx_prev) / INTERVAL ))
    tx_rate=$(( (tx_curr - tx_prev) / INTERVAL ))
    
    # Save current values
    rx_prev=$rx_curr
    tx_prev=$tx_curr
    
    # Get max interface capacity (assuming 1 Gbps)
    max_bandwidth=125000000 # 1 Gbps = 125 MB/s
    
    # Calculate percentages
    rx_percent=$(( rx_rate * 100 / max_bandwidth ))
    tx_percent=$(( tx_rate * 100 / max_bandwidth ))
    
    # Cap at 100%
    [[ $rx_percent -gt 100 ]] && rx_percent=100
    [[ $tx_percent -gt 100 ]] && tx_percent=100
    
    # Display
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
    
    # Alerts
    if [[ $rx_percent -ge $ALERT_THRESHOLD ]] || [[ $tx_percent -ge $ALERT_THRESHOLD ]]; then
        echo -e "${RED}⚠ ALERT: High bandwidth usage!${NC}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ALERT: RX=$rx_percent% TX=$tx_percent%" >> "$LOG_FILE"
    fi
    
    echo -e "${YELLOW}Last update: $(date '+%H:%M:%S')${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    
    # Log data
    echo "$(date '+%Y-%m-%d %H:%M:%S'),$rx_rate,$tx_rate,$rx_percent,$tx_percent" >> "$LOG_FILE"
    
    sleep "$INTERVAL"
done
