#!/bin/sh

# OpenSprinkler Configuration Monitor
# Monitors configuration files and triggers backups when changes are detected

PIDFILE="/var/run/ospi-config-monitor.pid"
OSPI_CONFIG_DIR="/usr/local/OpenSprinkler"
CONFIG_FILE="$OSPI_CONFIG_DIR/ospi_config.json"
BACKUP_SCRIPT="/usr/local/bin/ospi-backup-service.sh"
MONITOR_INTERVAL=30  # Check every 30 seconds

# Function to cleanup on exit
cleanup() {
    rm -f "$PIDFILE"
    exit 0
}

# Set up signal handlers
trap cleanup TERM INT

# Check if already running
if [ -f "$PIDFILE" ]; then
    if kill -0 $(cat "$PIDFILE") 2>/dev/null; then
        echo "Configuration monitor already running"
        exit 1
    else
        rm -f "$PIDFILE"
    fi
fi

# Write PID file
echo $$ > "$PIDFILE"

echo "Starting OpenSprinkler configuration monitor (PID: $$)"

# Main monitoring loop
while true; do
    if [ -x "$BACKUP_SCRIPT" ]; then
        "$BACKUP_SCRIPT" &
    fi
    
    sleep "$MONITOR_INTERVAL"
done