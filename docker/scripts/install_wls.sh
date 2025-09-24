#!/bin/bash
set -euo pipefail

JDK_ARCHIVE="${JDK_ARCHIVE:-jdk-8u202-linux-x64.tar.gz}"
FMW_INFRA_ZIP="${FMW_INFRA_ZIP:-fmw_12.2.1.4.0_infrastructure_Disk1_1of1.zip}"
FMW_INFRA_JAR="${FMW_INFRA_JAR:-fmw_12.2.1.4.0_infrastructure.jar}"
STAGE_DIR="/tmp/install/stage"
RESPONSE_DIR="/tmp/install/response"
ORACLE_INVENTORY="/u01/oraInventory"
JAVA_HOME="${JAVA_HOME:-/u01/java}"
ORACLE_HOME="${ORACLE_HOME:-/u01/oracle}"

assert_file() {
  local file="$1"
  if [[ ! -f "${file}" ]]; then
    echo "Required file not found: ${file}" >&2
    exit 1
  fi
}

mkdir -p "${JAVA_HOME}" "${ORACLE_HOME}" "${ORACLE_INVENTORY}"
chmod 775 "${ORACLE_INVENTORY}"

assert_file "${STAGE_DIR}/${JDK_ARCHIVE}"
assert_file "${STAGE_DIR}/${FMW_INFRA_ZIP}"

if [[ ! -x "${JAVA_HOME}/bin/java" ]]; then
  tar -xf "${STAGE_DIR}/${JDK_ARCHIVE}" -C "${JAVA_HOME}" --strip-components=1
fi

export JAVA_HOME
export PATH="${JAVA_HOME}/bin:${PATH}"

unzip -oq "${STAGE_DIR}/${FMW_INFRA_ZIP}" -d "${STAGE_DIR}"

INFRA_JAR_PATH="${STAGE_DIR}/${FMW_INFRA_JAR}"
if [[ ! -f "${INFRA_JAR_PATH}" ]]; then
  INFRA_JAR_PATH=$(find "${STAGE_DIR}" -maxdepth 1 -type f -name 'fmw_*infrastructure*.jar' | head -n 1 || true)
fi

if [[ -z "${INFRA_JAR_PATH}" || ! -f "${INFRA_JAR_PATH}" ]]; then
  echo "Could not locate infrastructure installer jar inside ${FMW_INFRA_ZIP}" >&2
  exit 1
fi

if [[ ! -d "${ORACLE_HOME}/inventory" ]]; then
  java -jar "${INFRA_JAR_PATH}" -silent \
    -responseFile "${RESPONSE_DIR}/fmw_infra.rsp" \
    -invPtrLoc /tmp/install/oraInst.loc \
    -ignoreSysPrereqs -force
else
  echo "Oracle Home already initialized; skipping infrastructure installer."
fi

rm -rf "${STAGE_DIR}"/*