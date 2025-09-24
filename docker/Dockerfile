# syntax=docker/dockerfile:1
FROM oraclelinux:8-slim

ARG JDK_ARCHIVE=jdk-8u202-linux-x64.tar.gz
ARG FMW_INFRA_ZIP=fmw_12.2.1.4.0_infrastructure_Disk1_1of1.zip
ARG FMW_INFRA_JAR=fmw_12.2.1.4.0_infrastructure.jar

ENV ORACLE_BASE=/u01/oracle \
    ORACLE_HOME=/u01/oracle \
    DOMAIN_BASE=/u01/domains \
    DOMAIN_NAME=adf_domain \
    JAVA_HOME=/u01/java \
    PATH=/u01/java/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:$PATH \
    JDK_ARCHIVE=${JDK_ARCHIVE} \
    FMW_INFRA_ZIP=${FMW_INFRA_ZIP} \
    FMW_INFRA_JAR=${FMW_INFRA_JAR}

RUN microdnf install -y tar gzip unzip libaio glibc-langpack-en shadow-utils python3 nmap-ncat hostname findutils && \
    microdnf clean all

RUN groupadd --gid 1000 oracle && \
    useradd --uid 1000 --gid oracle --home-dir /u01 --shell /bin/bash oracle && \
    mkdir -p /u01 && chown -R oracle:oracle /u01

COPY docker/oraInst.loc /tmp/install/oraInst.loc
COPY docker/response /tmp/install/response
COPY docker/scripts /opt/oracle/scripts
COPY docker/wlst /opt/oracle/wlst
COPY downloads/ /tmp/install/stage/

RUN chown -R oracle:oracle /opt/oracle /tmp/install /u01 && \
    chmod +x /opt/oracle/scripts/*.sh && \
    find /opt/oracle/scripts -type f -print0 | xargs -0 sed -i 's/\r$//' && \
    find /opt/oracle/wlst -type f -print0 | xargs -0 sed -i 's/\r$//' && \
    find /tmp/install/response -type f -print0 | xargs -0 sed -i 's/\r$//' && \
    sed -i 's/\r$//' /tmp/install/oraInst.loc

USER oracle

RUN /opt/oracle/scripts/install_wls.sh

USER oracle
WORKDIR /u01/oracle

EXPOSE 7001

ENTRYPOINT ["/opt/oracle/scripts/entrypoint.sh"]