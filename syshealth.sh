#!/usr/bin/env bash
# ==============================
# syshealth.sh - System health $ Log analysis toolkit
# Lab 1 - Data Collector
# Author - Saran saai dommaraju
# Date - $(date +%Y-%m-%d)
# ==============================

# ================================
# Defining the threshold variables 
# we do this because it mkaes the script easier to maintain. if we later want to change these limits it can be done in one 
# place. it makes the script more readable
# ================================
CPU_THRESHOLD=75
MEM_THRESHOLD=85
DISK_THRESHOLD=85

# ========================================
# Variables and demonstrating how to quote
# ========================================
HOSTNAME=$(hostname) # holds the output from hostname command
CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S') # hold the value from the date command

# When we use without quotes, word splitting bug occurs.
# So we use double quotes which is safer
echo "Hostname without quotes: $HOSTNAME" # works but causes word splitting bug
echo "Hostname with quotes: \"$HOSTNAME\"" #safe

cat << EOF # heredoc which allows us to feed multiple lines to a command at once

# Word splitting occurs in bash whenever we use unquoted variables. It splits the variables on spaces, tabs or newlines
# So we should always use double quoting unless we want splitting to happen

EOF
# =========================
# Collecting system metrics
# =========================
UPTIME=$(uptime -p) # how long the machine is running
DISK_USAGE=$(df -h / | tail -1) # storage usage
MEMORY_USAGE=$(free -h | awk '/Mem:/ {print $3 "/" $2}') # RAM usage
PROCESS_COUNT=$(ps -e | wc -l) # processes running

# OUTPUT_FILE stores the filename passed as an argument
# ${1:-} means if $1 is provided, use it, else use an empty string
OUTPUT_FILE="${1:-}" 

# ===============================
# Function to print system report
# ===============================
print_report() 
{
# Using printf for consistent formatting
printf "====================\n"
printf "System Health Report - %s\n" "$CURRENT_DATE" # prints health report
printf "Hostname     : %s\n" "$HOSTNAME" # prints hostname
printf "Uptime       : %s\n" "$UPTIME" # prints uptime
printf "Disk /       : %s\n" "$DISK_USAGE" # prints disk
printf "Memory used  : %s\n" "$MEMORY_USAGE" # prints memory used
printf "Total processes : %s\n" "$PROCESS_COUNT" # prints total proceses
printf "====================\n"
}

# To check if there was an argument given 
# -n checks if the variable length is zero
if [ -n "$OUTPUT_FILE" ]; then
	print_report > "$OUTPUT_FILE" # redirects the output to the given file
	echo "report written to $OUTPUT_FILE" 
else
	print_report # call print_report function which prints to the terminal
fi

# ================
# Exit status code
# ================

# Status code 0 is used to indicate successful execution
exit 0


# 














