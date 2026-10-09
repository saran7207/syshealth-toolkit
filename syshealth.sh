#!/usr/bin/env bash
# ==============================
# syshealth.sh - System health & Log analysis toolkit
# Lab 3 - Refactoring into Functions
# Author: Saran saai dommaraju
# Date: 2026-10-09
# ==============================

# ================================
# Defining the threshold variables 
# we do this because it makes the script easier to maintain. if we later want to change these limits it can be done at one 
# place. it makes the script more readable
# ================================
CPU_THRESHOLD=75
MEM_THRESHOLD=85
DISK_THRESHOLD=85

# Print a status message with a color based on the result
print_status() {
	local status="$1"
	local message="$2"
	
	# Print the message in green when the status is OK
	if [[ "$status" = "OK" ]]; then  
		echo -e "\e[32m OK: $message\e[0m" # -e flag is used to tell echo to use escape characters
	else
		# Print the message in red when there is an alert
		echo -e "\e[31m ALERT: $message\e[0m" # "[0m" is used to end the colored text and get it back to default
	fi
}

# Check the disk usage of a given mount point
check_disk_usage() {
	local mount="$1"
	local pct threshold
	threshold="$DISK_THRESHOLD"
	
	# Check whether the mount point exists
	# Skip the check when the mount point does not exist and is not the root directory
	if ! mountpoint -q "$mount" 2>/dev/null && [[ "$mount" != "/" ]]; then
		print_status "OK" "Mount point $mount does not exist on this system"
		return 0	
	fi
	
	# Get the disk usage percentage and remove the percent sign
	pct=$(df "$mount" | tail -1 | awk '{gsub("%",""); print $5}')
	
	# Compare the disk usage with the allowed limit
	if (( pct > threshold )); then
		print_status "ALERT" "Disk usage on $mount is ${pct}% (threshold ${threshold}%)"
		return 1
	else 
		print_status "OK" "Disk usage on $mount is ${pct}%"
		return 0
	fi
}

# Check how much memory is currently being used
check_memory_usage() {
	local pct threshold
	threshold="$MEM_THRESHOLD"
	
	# Calculate memory usage as a percentage of total memory
	pct=$(free | awk '/Mem:/ {printf "%.0f", $3/$2*100}')
	
	# Compare memory usage with the allowed limit
	if (( pct > threshold )); then
		print_status "ALERT" "Memory usage is ${pct}% (threshold ${threshold}%)"
		return 1
	else
		print_status "OK" "Memory usage is ${pct}%"
		return 0
	fi
}

# Check the current CPU usage
check_cpu_usage() {
	local pct threshold
	threshold="$CPU_THRESHOLD"
	
	# Get CPU usage by subtracting the idle percentage from 100
	pct=$(top -bn1 | grep '^%Cpu' | awk '{print 100 - $8}' | cut -d. -f1)
	
	# Compare CPU usage with the allowed limit
	if (( pct > threshold )); then
		print_status "ALERT" "CPU usage is ${pct}% (threshold ${threshold}%)"
		return 1
	else
		print_status "OK" "CPU usage is ${pct}%"
		return 0
	fi
}

# Run all system health checks and record the overall result
run_health_checks() {
	local overall_status=0
	local mount
	
	# Display a message before starting the checks
	print_status "CHECK" "Running system health analysis..."
	
	# Check disk usage for the root home and variable directories
	for mount in / /home /var; do
		if ! check_disk_usage "$mount"; then
			overall_status=1
		fi
	done
	
	# Check memory usage and record any failure
	if ! check_memory_usage; then
		overall_status=1
	fi
	
	# Check CPU usage and record any failure
	if ! check_cpu_usage; then
		overall_status=1
	fi
	
	# Save the overall result for use by other functions
	HEALTH_STATUS="$overall_status"
	# Return zero when all checks pass and one when any check fails
	return "$overall_status"
}

# Read the command line argument for the report file
parse_arguments() {
	# Use the first argument as the output file or leave it empty
	OUTPUT_FILE="${1:-}" 
}

# Generate a system health report with the current system information
generate_report() {
	local CURRENT_DATE HOSTNAME UPTIME DISK_USAGE MEMORY_USAGE PROCESS_COUNT
	
	CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S') # hold the value from the date command
	HOSTNAME=$(hostname) # holds the output from hostname command
	UPTIME=$(uptime -p) # how long the machine is running
	DISK_USAGE=$(df -h / | tail -1) # storage usage
	MEMORY_USAGE=$(free -h | awk '/Mem:/ {print $3 "/" $2}') # RAM usage
	PROCESS_COUNT=$(ps -e | wc -l) # processes running
	
	# Using printf for consistent formatting
	printf "====================\n"
	printf "System Health Report - %s\n" "$CURRENT_DATE" # prints health report
	printf "Hostname     : %s\n" "$HOSTNAME" # prints hostname
	printf "Uptime       : %s\n" "$UPTIME" # prints uptime
	printf "Disk /       : %s\n" "$DISK_USAGE" # prints disk
	printf "Memory used  : %s\n" "$MEMORY_USAGE" # prints memory used
	printf "Total processes : %s\n" "$PROCESS_COUNT" # prints total processes
	printf "Health status   : %s\n" "$([[ "${HEALTH_STATUS:-0}" -eq 0 ]] && echo "HEALTHY" || echo "UNHEALTHY - see alerts above")"
	printf "====================\n"
}

# Run the program from start to finish
main() {
	parse_arguments "$@" # Read the command line arguments
	
	run_health_checks # Run the system health checks
	
	# Save the report to a file when an output path is provided
	if [[ -n "$OUTPUT_FILE" ]]; then
		generate_report > "$OUTPUT_FILE"
		echo "Report written to $OUTPUT_FILE"
	else
		# Print the report to the terminal when no output file is provided
		generate_report
	fi
	# Exit with the overall health status
	exit "${HEALTH_STATUS:-0}"
}

# Starting the program
main "$@"

