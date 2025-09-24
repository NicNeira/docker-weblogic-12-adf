#!/bin/bash
set -euo pipefail

DOMAIN_NAME=${DOMAIN_NAME:-adf_domain}
DOMAIN_BASE=${DOMAIN_BASE:-/u01/domains}
DOMAIN_HOME=${DOMAIN_HOME:-${DOMAIN_BASE}/${DOMAIN_NAME}}
ADMIN_USERNAME=${ADMIN_USERNAME:-weblogic}
ADMIN_PASSWORD=${ADMIN_PASSWORD:?ADMIN_PASSWORD is required}
ORACLE_HOME=${ORACLE_HOME:-/u01/oracle}
WLST_SCRIPT=/opt/oracle/wlst/create_domain.py
RUN_RCU=${RUN_RCU:-true}

if [[ -f "${DOMAIN_HOME}/bin/startWebLogic.sh" ]]; then
  echo "Domain ${DOMAIN_NAME} already exists. Skipping creation."
  exit 0
fi

if [[ "${RUN_RCU}" != "false" ]]; then
  /opt/oracle/scripts/run_rcu.sh
else
  echo "RUN_RCU=false, skipping repository creation."
fi

"${ORACLE_HOME}/oracle_common/common/bin/wlst.sh" "${WLST_SCRIPT}"

SECURITY_DIR="${DOMAIN_HOME}/servers/AdminServer/security"
mkdir -p "${SECURITY_DIR}"
cat > "${SECURITY_DIR}/boot.properties" <<EOF
username=${ADMIN_USERNAME}
password=${ADMIN_PASSWORD}
EOF
chmod 600 "${SECURITY_DIR}/boot.properties"

echo "Domain ${DOMAIN_NAME} initialized."