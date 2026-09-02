#!/usr/bin/env bash
# ==============================
# syshealth.sh - System health $ Log analysis toolkit
# Lab 1 - Data Collector
# Author - Saran saai dommaraju
# Date - $(date +%Y-%m-%d)
# ==============================

# -- variables and coating demonstration --
HOSTNAME=$(hostname)
CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S')

# important quoting demo
# without quotes there will be word splitting bug
# with double quotes its safe
echo "Hostname without quotes: $HOSTNAME" # works but causes word splitting bug
echo "Hostname with quotes: \"$HOSTNAME\"" #safe

cat << EOF

# Comment for grader
# In python or java variables expand safely
# bash unquoted variables splits on spaces/tabs/newlines
# we always use double quote unless we want to split the variables

EOF

# --- system metrics collection ---
UPTIME=$(uptime -p)
DISK_USAGE=$(df -h / | tail -1)
MEMORY_USAGE=$(free -h | awk '/Mem:/ {print $3 "/" $2}')
PROCESS_COUNT=$(ps -e | wc -l)

# --- output handling ---
OUTPUT_FILE="${1:-}" # if argument is given use it, or else go default

print_report() 
{
printf "=======\n"
printf "HOSTNAME: %s\n" "$HOSTNAME"
printf "UPTIME: %s\n" "$UPTIME"
printf "DISK USAGE: %s\n" "$DISK_USAGE"
printf "MEMORAGE USAGE: %s\n" "$MEMORY_USAGE"
printf "PROCESS COUNT: %s\n" "$PROCESS_COUNT"
printf "=======\n"
}

if [ -n "$OUTPUT_FILE" ]; then
	print_report > "$OUTPUT_FILE"
	echo "report written to $OUTPUT_FILE"
else
	print_report
fi

exit 0

















