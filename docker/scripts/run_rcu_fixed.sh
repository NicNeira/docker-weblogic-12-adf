#!/bin/bash
set -euo pipefail

RCU_PREFIX=${RCU_PREFIX:?RCU_PREFIX is required}
RCU_SCHEMA_PASSWORD=${RCU_SCHEMA_PASSWORD:?RCU_SCHEMA_PASSWORD is required}
RCU_DB_PASSWORD=${RCU_DB_PASSWORD:?RCU_DB_PASSWORD is required}
RCU_DB_HOST=${RCU_DB_HOST:-db}
RCU_DB_PORT=${RCU_DB_PORT:-1521}
RCU_DB_SERVICE=${RCU_DB_SERVICE:-XEPDB1}
RCU_DB_USER=${RCU_DB_USER:-sys}
RCU_DB_ROLE=${RCU_DB_ROLE:-SYSDBA}
RCU_WAIT_TIMEOUT=${RCU_WAIT_TIMEOUT:-600}
ORACLE_HOME=${ORACLE_HOME:-/u01/oracle}
MARKER_FILE="/tmp/.${RCU_PREFIX}.rcu.done"

# Check if already completed
if [[ -f "${MARKER_FILE}" ]]; then
  echo "RCU repository already marked as created."
  exit 0
fi

CONNECT_STRING="${RCU_DB_HOST}:${RCU_DB_PORT}/${RCU_DB_SERVICE}"
RCU_BIN="${ORACLE_HOME}/oracle_common/bin/rcu"

if [[ ! -x "${RCU_BIN}" ]]; then
  echo "RCU binary not found at ${RCU_BIN}" >&2
  exit 1
fi

# Wait for database
echo "Waiting for database ${RCU_DB_HOST}:${RCU_DB_PORT}..."
python3 - <<'PY' || { echo "Timed out waiting for database" >&2; exit 1; }
import os, socket, sys, time
host=os.environ.get('RCU_DB_HOST','db'); port=int(os.environ.get('RCU_DB_PORT','1521')); timeout=int(os.environ.get('RCU_WAIT_TIMEOUT','600'))
t=time.time()
while True:
    try:
        with socket.create_connection((host,port),timeout=5): sys.exit(0)
    except Exception:
        if time.time()-t>timeout: sys.exit(1)
        time.sleep(5)
PY

echo "Database is ready. Checking for existing schemas..."

# Check if schemas already exist using listSchemas
set +e
echo "${RCU_DB_PASSWORD}" | "${RCU_BIN}" -silent -listSchemas \
  -databaseType ORACLE \
  -connectString "${CONNECT_STRING}" \
  -dbUser "${RCU_DB_USER}" \
  -dbRole "${RCU_DB_ROLE}" \
  -schemaPrefix "${RCU_PREFIX}" > /dev/null 2>&1

SCHEMAS_EXIST=$?
set -e

if [[ ${SCHEMAS_EXIST} -eq 0 ]]; then
  echo "RCU schemas for prefix ${RCU_PREFIX} already exist."
  touch "${MARKER_FILE}"
  echo "RCU process completed - using existing schemas."
  exit 0
fi

echo "Creating new RCU repository for prefix ${RCU_PREFIX}..."

# Create new schemas
echo -e "${RCU_DB_PASSWORD}\n${RCU_SCHEMA_PASSWORD}" | "${RCU_BIN}" -silent -createRepository \
  -databaseType ORACLE \
  -connectString "${CONNECT_STRING}" \
  -dbUser "${RCU_DB_USER}" \
  -dbRole "${RCU_DB_ROLE}" \
  -schemaPrefix "${RCU_PREFIX}" \
  -useSamePasswordForAllSchemaUsers true \
  -selectDependentsForComponents true \
  -component STB \
  -component WLS \
  -component OPSS \
  -component MDS \
  -component IAU \
  -component IAU_APPEND \
  -component IAU_VIEWER

echo "RCU repository created successfully for prefix ${RCU_PREFIX}."
touch "${MARKER_FILE}"
echo "RCU process completed successfully."