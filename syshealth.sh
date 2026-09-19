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

# This function prints either an OK or ALERT message in color.
# Using a function avoids repeating the same echo logic everywhere.
#
# 'local' is used so 'status' and 'message' do not overwrite variables
# outside the function. Without 'local', these names could accidentally
# collide with global variables, causing unpredictable behavior.
#
# Inside [ ], '=' is the POSIX-standard string comparison operator.
# '==' works in Bash but is not portable; '-eq' is numeric-only.
print_status() 
{
local status="$1"
local message="$2"
if [ "$status" = "OK" ]; then # we use = becuase its the posix standard strin comparison operator insdie []
	echo -e "\e[32m OK: $message\e[0m" # -e flag is used to tell echo to use escape characters
else
	echo -e "\e[31m ALERT: $message\e[0m" # [0m is used to end the colored text and get it back to default
fi
}

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

# ========================================================================
# Numeric metrics for threshold comparison
# These versions remove symbols and formatting so arithmetic can be done.
# ========================================================================

# df prints disk usage like "85%". gsub("%","") removes the % so the value
# becomes a pure integer. If gsub were skipped, arithmetic comparison would fail.
DISK_PCT=$(df / | tail -1 | awk '{gsub("%",""); printf $5}') 

# free prints memory usage as raw numbers. printf "%.0f" rounds the result
# to a whole number. Using plain 'print' may produce decimals, which break (( )).
MEM_PCT=$(free | awk '/Mem:/ {printf "%.0f", $3/$2*100}') 

# CPU extraction pipeline:
# top -bn1 → batch mode, one iteration, non-interactive
# grep '^%CPU' → isolate the CPU summary line
# awk '{print 100 - $8}' → subtract idle percentage to get usage
# cut -d. -f1 → remove decimals for integer comparison
CPU_PCT=$(top -bn1 | grep '^%CPU' | awk '{print 100 - $8}' | cut -d. -f1)

print_status "CHECK" "Running system health analysis..."

# HEALTH_STATUS acts as a flag:
# 0 = everything healthy
# 1 = at least one alert occurred
# It is never reset back to 0 because once a failure happens,
# the system is considered unhealthy overall.
HEALTH_STATUS=0

# Disk usage check for root /
# (( )) is used because it performs arithmetic comparison directly.
# [ ] would require -gt and quoting, and is less readable for math.
if (( DISK_PCT > DISK_THRESHOLD )); then
	print_status "ALERT" "Disk usage on / is ${DISK_PCT}% (threshold ${DISK_THRESHOLD}%)"
	HEALTH_STATUS=1
else 
	print_status "OK" "Disk usage on / is ${DISK_PCT}%"
fi

# ==========================================================
# Loop through multiple mount points
# Using a loop avoids repeating the same code three times.
# Adding or removing mount points becomes trivial.
# ==========================================================
for mount in / /home /var; do

	# mountpoint -q suppresses normal output; 2>/dev/null hides error messages
    	# such as "not a mountpoint". The fallback [ "$mount" = "/" ] ensures
    	# root is always treated as valid even if mountpoint behaves differently.
	if mountpoint -q "$mount" 2>/dev/null || [ "$mount" = "/" ]; then
	
		# Remove % sign for numeric comparison
		PCT=$(df "$mount" | tail -1 | awk '{gsub("%",""); print $5}')
		# Compare mount usage against threshold
		if (( PCT > DISK_PCT )); then
			print_status "ALERTS" "Disk usage on $mount is ${PCT}% (threshold ${DISK_PCT}%)"
			HEALTH_STATUS=1
		else
			print_status "OK" "Disk usage on $mount is ${PCT}%"
		fi
	else
		print_status "OK" "Mount point $mount does not exist or is not a mountpoint on this system"
	fi
done


# ===========================
# Memory usage check
# ===========================
if (( MEM_PCT > MEM_THRESHOLD )); then
	print_status "ALERT" "Memory usage ${MEM_PCT}% (threshold ${MEM_THRESHOLD}%)"
	HEALTH_STATUS=1
else
	print_status "OK" "Memory usage is ${DISK_PCT}%"
fi

# ===========================
# CPU usage check
# ===========================
if (( CPU_PCT > CPU_THRESHOLD )); then
	print_status "ALERT" "Cpu usage is ${CPU_PCT}% (threshold ${CPU_THRESHOLD}%)"
	HEALTH_STATUS=1
else 
	print_status "OK" "CPU usage is ${CPU_PCT}%"
fi


# ===========================
# Output file handling
# ${1:-} means: use argument 1 if provided, otherwise empty string.
# ===========================
OUTPUT_FILE="${1:-}" 

# ===============================
# print_report() — final summary
# printf is used for consistent formatting.
# The health status line uses && and ||:
# command && A || B means:
# If command succeeds, run A; otherwise run B.
# Only one of the two echoes will run.
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
printf "Health status   : %s\n" "$([ "$HEALTH_STATUS" -eq 0 ] && echo "HEALTHY" || echo "UNHEALTHY - See alerts above")"
printf "====================\n"
}

# ===========================
# Write report to file or terminal
# -n checks if OUTPUT_FILE is non-empty.
# ===========================
if [ -n "$OUTPUT_FILE" ]; then
	print_report > "$OUTPUT_FILE" # redirects the output to the given file
	echo "Report written to $OUTPUT_FILE (alerts were printed to terminal)" 
else
	print_report # call print_report function which prints to the terminal
fi

# ===========================
# Exit code
# Exit codes matter because other programs (cron, systemd, CI pipelines)
# rely on them to detect success/failure. Humans may read the report,
# but automation reads the exit code.
# ===========================
exit "${HEALTH_STATUS:-0}"

















