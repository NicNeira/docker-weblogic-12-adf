# WebLogic + Oracle ADF en contenedores

Este proyecto levanta un dominio de WebLogic 12.2.1.4 con las bibliotecas de Oracle ADF Runtime dentro de un contenedor Docker. Se incluye un contenedor adicional con Oracle Database XE para hospedar los esquemas creados vÃƒÂ­a RCU.

## Requisitos previos

- Docker 20.10 o superior y Docker Compose v2.
- Acceso a los binarios licenciados de Oracle:
  - `jdk-8u202-linux-x64.tar.gz` (u otra distribuciÃƒÂ³n soportada de Oracle JDK 8).
  - `fmw_12.2.1.4.0_infrastructure_Disk1_1of1.zip` (contiene `fmw_12.2.1.4.0_infrastructure.jar`).

> **Importante:** Desde la versiÃƒÂ³n 12.2.1.4 Oracle distribuye ADF Runtime dentro del instalador de Fusion Middleware Infrastructure. No existe un paquete con nombre `adf_Disk1`; si el instalador no encuentra el tipo "ADF Runtime" es porque estÃƒÂ¡s reutilizando un response file antiguo. Este proyecto ya usa el tipo correcto (`Fusion Middleware Infrastructure`) siguiendo la guÃƒÂ­a oficial de Oracle.

## PreparaciÃƒÂ³n del entorno

1. Copia los instaladores anteriores dentro de la carpeta `downloads/` respetando los nombres indicados.
2. Si el `jar` interno tuviese un nombre diferente, ajusta la variable `FMW_INFRA_JAR` en tu `.env`.
3. No modifiques la base de datos del contenedor: el PDB `XEPDB1` ya viene creado por defecto en Oracle XE.
4. Duplica el archivo `.env.sample` con el nombre `.env` y ajusta las credenciales según tus necesidades.

## ConstrucciÃƒÂ³n y arranque

```powershell
# Construir la imagen (requiere que los instaladores estÃƒÂ©n en downloads/)
docker compose build weblogic

# Iniciar los contenedores (primer arranque ejecuta RCU y puede tardar varios minutos)
docker compose up -d

# Seguir lo que ocurre en WebLogic
docker compose logs -f weblogic
```

La consola de administraciÃƒÂ³n estarÃƒÂ¡ disponible en `http://localhost:7001/console` una vez que el servidor termine de iniciar. Usa las credenciales configuradas en `.env` (por defecto `weblogic` / `Welcome1`).

## Componentes principales

- `docker/Dockerfile`: Construye la imagen con Oracle Linux, Oracle JDK 8 y Fusion Middleware Infrastructure (que incluye ADF Runtime) usando un ÃƒÂºnico instalador.
- `docker/scripts/install_wls.sh`: Instala JDK e Infrastructure en modo silencioso.
- `docker/scripts/run_rcu.sh`: Crea (o reutiliza) los esquemas RCU necesarios en la base de datos.
- `docker/scripts/create_domain.sh` + `docker/wlst/create_domain.py`: Generan un dominio con plantillas JRF y ADF y configuran las fuentes JDBC contra la base de datos.
- `docker/scripts/entrypoint.sh`: Inicializa el dominio si aÃƒÂºn no existe y deja el AdminServer en primer plano.
- `docker-compose.yml`: Orquesta los contenedores de base de datos y WebLogic, ademÃƒÂ¡s de definir un volumen persistente para los dominios.

## PersonalizaciÃƒÂ³n y consideraciones

- **Base de datos:** Se usa `gvenzl/oracle-xe:21-slim` por simplicidad. Si cuentas con otra base certificada puedes ajustar `RCU_DB_HOST`, `RCU_DB_PORT` y `RCU_DB_SERVICE` en `.env`.
- **Prefijo RCU:** Cambia `RCU_PREFIX` para evitar colisiones si compartes la base con otros entornos.
- **ContraseÃƒÂ±as:** Sustituye las contraseÃƒÂ±as de ejemplo antes de poner esto en producciÃƒÂ³n.
- **Persistencia:** Los dominios viven en el volumen `weblogic_domains`. Elimina el volumen (`docker volume rm weblogic-local-adf_weblogic_domains`) si necesitas recrear el dominio desde cero.

## Ciclo de vida

```powershell
# Detener contenedores
docker compose down

# Detener y eliminar contenedores, manteniendo volumen y redes
docker compose down --remove-orphans

# Eliminar tambiÃƒÂ©n el volumen persistente (cuidado: borra el dominio)
docker compose down -v
```

## SoluciÃƒÂ³n de problemas

- **ConstrucciÃƒÂ³n falla por archivos faltantes:** Verifica que el `.zip` y el `.tar.gz` estÃƒÂ©n en `downloads/` y sus nombres coincidan con los definidos en `.env`.
- **No aparece "ADF Runtime" en la instalaciÃƒÂ³n:** La opciÃƒÂ³n correcta para 12.2.1.4 es "Fusion Middleware Infrastructure". Este proyecto ya usa ese valor en el response file `docker/response/fmw_infra.rsp`.
- **RCU no puede conectarse:** AsegÃƒÂºrate de que el contenedor `db` terminÃƒÂ³ su arranque (healthcheck en estado `healthy`) y que la contraseÃƒÂ±a de `SYS` coincide con `ORACLE_PASSWORD`.
- **Inicio muy lento:** El primer arranque ejecuta RCU y crea el dominio; puede tardar ~10-15 minutos dependiendo de los recursos asignados.
- **Reintentos de RCU:** El script detecta esquemas existentes usando `rcu -listManagedSchemas`. Si necesitas recrearlos, elimina el volumen de base de datos o cambia el prefijo.

## PrÃƒÂ³ximos pasos

- Crea un cluster y Managed Servers adicionales si tu proyecto ADF lo requiere.
- Integra tus despliegues ADF en un pipeline que haga push de EAR/WAR al contenedor WebLogic.
