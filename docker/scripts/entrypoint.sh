#!/bin/bash
set -euo pipefail

DOMAIN_NAME=${DOMAIN_NAME:-adf_domain}
DOMAIN_BASE=${DOMAIN_BASE:-/u01/domains}
DOMAIN_HOME=${DOMAIN_HOME:-${DOMAIN_BASE}/${DOMAIN_NAME}}
LOG_DIR="${DOMAIN_HOME}/servers/AdminServer/logs"
ADMIN_SERVER_OUT="${LOG_DIR}/AdminServer.out"

/opt/oracle/scripts/create_domain.sh

mkdir -p "${LOG_DIR}"
touch "${ADMIN_SERVER_OUT}"

"${DOMAIN_HOME}/bin/startWebLogic.sh" &
START_PID=$!

tail -n 0 -F "${ADMIN_SERVER_OUT}" &
TAIL_PID=$!

shutdown() {
  echo "Recibida seÃƒÂ±al, deteniendo WebLogic..."
  "${DOMAIN_HOME}/bin/stopWebLogic.sh" || kill ${START_PID} >/dev/null 2>&1 || true
  kill ${TAIL_PID} >/dev/null 2>&1 || true
}

trap shutdown SIGINT SIGTERM

wait ${START_PID} || true
wait ${TAIL_PID} || true