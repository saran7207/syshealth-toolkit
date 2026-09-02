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

