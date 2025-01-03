#!/bin/bash

# Log file path in the temporary directory
LOG_FILE="/nio/deploy/run-edge.log"

# Infinite loop to run as a daemon
while true; do
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Fetching new config" >> "$LOG_FILE"
  sleep 60  # Wait for 60 seconds
done
