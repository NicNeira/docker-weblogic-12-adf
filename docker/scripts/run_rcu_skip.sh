#!/bin/bash
set -euo pipefail

RCU_PREFIX=${RCU_PREFIX:?RCU_PREFIX is required}
MARKER_FILE="/tmp/.${RCU_PREFIX}.rcu.done"

echo "Skipping RCU creation - assuming schemas already exist for prefix ${RCU_PREFIX}."
echo "Creating marker file to indicate RCU process is complete..."

# Create the marker file to indicate RCU is done
touch "${MARKER_FILE}"

echo "RCU process marked as completed. Proceeding to domain creation..."