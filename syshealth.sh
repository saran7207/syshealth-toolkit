#!/usr/bin/env bash
# ==============================
# syshealth.sh - System health $ Log analysis toolkit
# Lab 1 - Data Collector
# Author - Saran saai dommaraju
# Date - $(date +%Y-%m-%d)
# ==============================

# Variables and demonstrating how to quote
HOSTNAME=$(hostname)
CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S')

# When we use without quotes, word splitting bug occurs.
# So we use double quotes which is safer
echo "Hostname without quotes: $HOSTNAME" # works but causes word splitting bug
echo "Hostname with quotes: \"$HOSTNAME\"" #safe

cat << EOF

# Word splitting occurs in bash whenever we use unquoted variables. It splits the variables on spaces, tabs or newlines
# So we should always use double quoting unless we want splitting to happen

EOF

# Collecting system metrics
UPTIME=$(uptime -p) # how long the machine is running
DISK_USAGE=$(df -h / | tail -1) # storage usage
MEMORY_USAGE=$(free -h | awk '/Mem:/ {print $3 "/" $2}') # RAM usage
PROCESS_COUNT=$(ps -e | wc -l) # processes running

# Handling the output
OUTPUT_FILE="${1:-}" # if argument is given use it, or else go default

# Function to print system report
print_report() 
{
printf "====================\n"
printf "System Health Report - %s\n" "$CURRENT_DATE"
printf "Hostname     : %s\n" "$HOSTNAME"
printf "Uptime       : %s\n" "$UPTIME"
printf "Disk /       : %s\n" "$DISK_USAGE"
printf "Memory used  : %s\n" "$MEMORY_USAGE"
printf "Total processes : %s\n" "$PROCESS_COUNT"
printf "====================\n"
}

# To check if there was an argument given 
if [ -n "$OUTPUT_FILE" ]; then
	print_report > "$OUTPUT_FILE"
	echo "report written to $OUTPUT_FILE"
else
	print_report
fi

# Exit status code
exit 0

















