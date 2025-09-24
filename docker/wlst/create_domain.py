import glob
import os


def env(name, default=None, required=False):
    value = os.environ.get(name, default)
    if required and not value:
        raise ValueError("Environment variable %s is required" % name)
    return value


def resolve_template(pattern, required=True):
    matches = glob.glob(pattern)
    matches.sort()
    if not matches:
        if required:
            raise ValueError("No template found for pattern %s" % pattern)
        print('Info - optional template not found for pattern %s' % pattern)
        return None
    return matches[-1]


def main():
    oracle_home_raw = env('ORACLE_HOME', '/u01/oracle')
    oracle_home = os.path.normpath(oracle_home_raw)

    # WLST puede exportar ORACLE_HOME apuntando a oracle_common; normalizamos a MW home
    if os.path.basename(oracle_home) == 'oracle_common':
        mw_home = os.path.dirname(oracle_home)
        oracle_common_home = oracle_home
    else:
        mw_home = oracle_home
        oracle_common_home = os.path.join(oracle_home, 'oracle_common')

    java_home = env('JAVA_HOME', '/u01/java')
    domain_name = env('DOMAIN_NAME', 'adf_domain')
    domain_home = env('DOMAIN_HOME', os.path.join('/u01/domains', domain_name))
    admin_user = env('ADMIN_USERNAME', 'weblogic')
    admin_password = env('ADMIN_PASSWORD', required=True)
    admin_port = int(env('ADMIN_PORT', '7001'))
    admin_address = env('ADMIN_LISTEN_ADDRESS', '')

    rcu_prefix = env('RCU_PREFIX', required=True)
    rcu_schema_password = env('RCU_SCHEMA_PASSWORD', required=True)
    db_host = env('RCU_DB_HOST', 'db')
    db_port = env('RCU_DB_PORT', '1521')
    db_service = env('RCU_DB_SERVICE', 'XEPDB1')

    # Ensure all values are strings
    db_host = str(db_host)
    db_port = str(db_port)
    db_service = str(db_service)

    print('Debug - MW_HOME: %s, OracleCommon: %s' % (mw_home, oracle_common_home))
    print('Debug - db_host: %s, db_port: %s, db_service: %s' % (db_host, db_port, db_service))

    db_url = 'jdbc:oracle:thin:@//' + db_host + ':' + db_port + '/' + db_service

    wls_template = os.path.join(mw_home, 'wlserver', 'common', 'templates', 'wls', 'wls.jar')
    jrf_template = resolve_template(os.path.join(oracle_common_home, 'common', 'templates', 'wls', 'oracle.jrf_template*.jar'))
    em_template = resolve_template(os.path.join(oracle_common_home, 'common', 'templates', 'wls', 'oracle.em_common_template*.jar'), required=False)
    adf_template = resolve_template(os.path.join(oracle_common_home, 'common', 'templates', 'wls', 'adf.oracle.domain*.jar'))

    readTemplate(wls_template)

    set('Name', domain_name)
    setOption('DomainName', domain_name)
    setOption('OverwriteDomain', 'true')
    setOption('JavaHome', java_home)
    setOption('ServerStartMode', 'dev')

    cd('/Security/base_domain/User/weblogic')
    cmo.setName(admin_user)
    cmo.setPassword(admin_password)

    addTemplate(jrf_template)
    if em_template:
        addTemplate(em_template)
    else:
        print('Info - skipping Enterprise Manager template because it is unavailable.')
    addTemplate(adf_template)

    cd('/JDBCSystemResource/LocalSvcTblDataSource/JdbcResource/LocalSvcTblDataSource/JdbcDriverParams/NO_NAME_0')
    cmo.setUrl(db_url)
    cmo.setPassword(rcu_schema_password)

    cd('Properties/NO_NAME_0/Property/user')
    cmo.setValue(rcu_prefix + '_STB')

    getDatabaseDefaults()

    cd('/Servers/AdminServer')
    cmo.setListenPort(admin_port)
    if admin_address:
        cmo.setListenAddress(admin_address)

    setServerGroups('AdminServer', ['JRF-MAN-SVR', 'ADF-MGD-SVR'])

    domain_dir = domain_home
    domain_parent = os.path.dirname(domain_dir)
    if domain_parent and not os.path.exists(domain_parent):
        os.makedirs(domain_parent)

    writeDomain(domain_dir)
    closeTemplate()

    print('ADF domain created at %s' % domain_dir)


main()