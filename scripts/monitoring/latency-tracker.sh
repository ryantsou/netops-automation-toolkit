#!/bin/bash

# Latency Tracker - Multi-site latency monitoring
# Author: Riantsoa Rajhonson
# Usage: ./latency-tracker.sh -f <hosts_file> -c <count>

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

HOSTS_FILE="config/hosts.txt"
COUNT=10
INTERVAL=1
LOG_FILE="logs/latency-$(date +%Y%m%d).csv"
ALERT_THRESHOLD=100 # ms

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Latency and jitter monitoring between multiple sites.

OPTIONS:
    -f, --file <path>         File containing hosts to monitor
    -c, --count <number>      Number of pings per host (default: 10)
    -i, --interval <seconds>  Interval between tests (default: 1s)
    -l, --log <file>          CSV log file
    -a, --alert <ms>          Alert threshold in milliseconds (default: 100)
    -h, --help                Display this help

HOSTS FILE FORMAT:
    hostname or IP per line
    Example: 8.8.8.8

EXAMPLES:
    $(basename "$0") -f config/hosts.txt -c 20
    $(basename "$0") -f sites.txt -c 50 -a 150

AUTHOR:
    Riantsoa Rajhonson - NetOps Automation Toolkit
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file) HOSTS_FILE="$2"; shift 2 ;;
        -c|--count) COUNT="$2"; shift 2 ;;
        -i|--interval) INTERVAL="$2"; shift 2 ;;
        -l|--log) LOG_FILE="$2"; shift 2 ;;
        -a|--alert) ALERT_THRESHOLD="$2"; shift 2 ;;
        -h|--help) show_help; exit 0 ;;
        *) echo -e "${RED}Error: Unknown option: $1${NC}"; show_help; exit 1 ;;
    esac
done

if [[ ! -f "$HOSTS_FILE" ]]; then
    echo -e "${RED}Error: File $HOSTS_FILE not found${NC}"
    exit 1
fi

mkdir -p "$(dirname "$LOG_FILE")"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Latency Tracker - Multi-Site Monitor          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Initialize CSV file
if [[ ! -f "$LOG_FILE" ]]; then
    echo "timestamp,host,min_ms,avg_ms,max_ms,stddev_ms,packet_loss,status" > "$LOG_FILE"
fi

ping_host() {
    local host=$1
    local count=$2
    
    echo -e "${YELLOW}Testing: $host${NC}"
    
    # Execute ping and capture results
    local ping_output=$(ping -c "$count" -i "$INTERVAL" -W 2 "$host" 2>&1)
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        echo -e "  ${RED}✗ Unreachable${NC}"
        echo "$(date '+%Y-%m-%d %H:%M:%S'),$host,0,0,0,0,100,UNREACHABLE" >> "$LOG_FILE"
        return 1
    fi
    
    # Parse statistics
    local stats=$(echo "$ping_output" | grep "rtt min/avg/max/mdev")
    local packet_loss=$(echo "$ping_output" | grep "packet loss" | awk '{print $6}' | tr -d '%')
    
    if [[ -n "$stats" ]]; then
        local min=$(echo "$stats" | awk -F'[/=]' '{print $6}')
        local avg=$(echo "$stats" | awk -F'[/=]' '{print $7}')
        local max=$(echo "$stats" | awk -F'[/=]' '{print $8}')
        local stddev=$(echo "$stats" | awk -F'[/=]' '{print $9}' | awk '{print $1}')
        
        # Round values
        min=$(printf "%.0f" "$min")
        avg=$(printf "%.0f" "$avg")
        max=$(printf "%.0f" "$max")
        stddev=$(printf "%.0f" "$stddev")
        
        # Determine status
        local status="OK"
        local color=$GREEN
        if (( $(echo "$avg > $ALERT_THRESHOLD" | bc -l) )); then
            status="HIGH_LATENCY"
            color=$RED
        fi
        
        if (( $(echo "$packet_loss > 5" | bc -l) )); then
            status="PACKET_LOSS"
            color=$RED
        fi
        
        echo -e "  ${color}✓ Min: ${min}ms | Avg: ${avg}ms | Max: ${max}ms | Loss: ${packet_loss}%${NC}"
        
        if [[ "$status" != "OK" ]]; then
            echo -e "  ${RED}⚠ ALERT: $status${NC}"
        fi
        
        # Log
        echo "$(date '+%Y-%m-%d %H:%M:%S'),$host,$min,$avg,$max,$stddev,$packet_loss,$status" >> "$LOG_FILE"
    fi
    
    echo ""
}

# Main loop
while true; do
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              Latency Tracker - Multi-Site Monitor          ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${YELLOW}Tests: $COUNT pings | Interval: ${INTERVAL}s | Alert: ${ALERT_THRESHOLD}ms${NC}"
    echo -e "${YELLOW}Time: $(date '+%H:%M:%S') | Log: $LOG_FILE${NC}"
    echo ""
    
    while IFS= read -r host || [[ -n "$host" ]]; do
        [[ -z "$host" || "$host" =~ ^# ]] && continue
        ping_host "$host" "$COUNT"
    done < "$HOSTS_FILE"
    
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    sleep 10
done
