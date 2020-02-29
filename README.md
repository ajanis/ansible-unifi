# Ansible role for Unifi Admin service with metrics provided by Prometheus and Telegraf + InfluxDB
This role makes use of [This Docker Role](https://github.com/ajanis/ansible-docker) to deploy the Ubiquiti Unifi Admin service along with a Prometheus metrics exporter container and the Telegraf metrics collector along with required SNMP MIBS/configurations.

## Example using group_vars
This is an example of how to use this role to deploy the Ubiquiti Unifi Admin controller and a Prometheus metrics collector for Unifi Admin

### docker_containers and docker_build_images group_vars for Unifi Admin and Unifi-Exporter
Calls the docker role with the following group_vars to build a docker image from the specified git repo and deploy the containerized service and systemd configs.


#### defaults/main.yml
```yaml
---
data_mount_root: /data
configs_directory: configs

unms_version: 1.1.5

unms_config_directory: "{{ data_mount_root }}/{{ configs_directory }}/unms"
unms_data_directory: "{{ unms_config_directory }}/data"
unms_app_directory: "{{ unms_config_directory }}/app"
unms_pgconf_directory: "{{ unms_app_directory }}/conf/postgres"
unms_yarn_directory: "{{ unms_app_directory }}/.yarn"
unms_log_directory: "{{ unms_data_directory }}/logs"
unms_redis_directory: "{{ unms_data_directory }}/redis"
unms_postgres_directory: "{{ unms_data_directory }}/postgres"
unms_rabbitmq_directory: "{{ unms_data_directory }}/rabbitmq"
unms_ucrm_directory: "{{ unms_data_directory }}/ucrm"
unms_firmware_directory: "{{ unms_data_directory }}/firmwares"
unms_cert_directory: "{{ unms_data_directory }}/cert"
unms_enable_ssl: False

unms_user_id: "1000"

unms_postgres_host: "unms-postgres"
unms_admin_postgres_user: "root"
unms_admin_postgres_password: "jh6UE6RI5xtPqtHbs1WQkZepftu4IH9NX2SgnkQIbBxXFCXP"
unms_unms_postgres_db: "unms"
unms_unms_postgres_schema: "unms"
unms_unms_postgres_user: "unms"
unms_unms_postgres_password: "h6AP3aPIkuDlj8iyDuh9mv3S5yul2HupLLLZIH39MuXJC8gf"
unms_ucrm_postgres_db: "unms"
unms_ucrm_postgres_schema: "ucrm"
unms_ucrm_postgres_user: "ucrm"
unms_ucrm_postgres_password: "ypELME0RTpkwi045ELL8sHGF6ZAJE4TEPbu5hmnqIXpzdjMF"
unms_pgdata: "/var/lib/postgresql/data/pgdata"
unms_demo: "false"
unms_node_env: "production"
unms_http_port: "8081"
unms_ws_port: "8082"
unms_ws_shell_port: "8083"
unms_ws_api_port: "8084"
unms_netflow_port: "2055"
unms_public_https_port: "443"
unms_public_ws_port: ""
unms_nginx_https_port: "443"
unms_nginx_http_port: "80"
unms_ssl_cert: "localhost.crt"
unms_ssl_cert_key: "localhost.key"
unms_ssl_cert_ca: ""
unms_ip_whitelist: ""
unms_suspend_port: "81"
unms_host_tag: ""
unms_branch: "master"
unms_http_proxy: ""
unms_https_proxy: ""
unms_no_proxy: ""
unms_secure_link_secret: "3p8Vkj5FK8fgZI7k0NdiXze5XDQgCoil2wrFoASaHymMbx0TS1sAcJxmpl342s3ZgQbfKSJHsZym1pZSui558rHiBwxSB09A89MA"
unms_cluster_size: "auto"
unms_token: "oMoPnh7RUabnFmRuwBcIdmACGeKYsPI6qw69qAro3Njv62vw"
unms_deployment: ""
unms_features: ""
unms_use_local_discovery: "true"
unms_mailer_address: "127.1.0.1"
unms_mailer_address_username: "username"
unms_mailer_address_password: "password"
unms_secret: "BPee0eCuyJqmcpqCDA2WjzKtCXP1b2k7aerqdDV0QxOvAvoe"
unms_ucrm_user: "unms"
unms_host: "unms"
unms_base_url: "/v2.1"
unms_fluentd_port: "24224"
unms_rabbitmq_server_additional_erl_args: "-rabbit channel_max 4096"
docker_unifi_container_name: unifi
unifi_admin_host: "unifi.{{ www_domain | default('example.com') }}"
unifi_admin_url: "https://{{ unifi_admin_host }}:8443"
unifi_config_directory: "{{ data_mount_root }}/{{ configs_directory }}/unifi"
unifi_data_directory: '{{ unifi_config_directory }}/data'
unifi_container_data_directory: /config/data
unifi_container_java_directory: /usr/lib/jvm/java-1.8.0-openjdk-amd64
unifi_enable_ssl: False

unifi_snmp_v3_password: "{{ vault_unifi_snmp_v3_password | default('') }}"
unifi_snmp_v3_username: telegraf

unifi_exporter_config_directory: "{{ data_mount_root }}/{{ configs_directory }}/unifi_exporter"
unifi_admin_site: default


ssl_privkey:
ssl_certchain:

ssl_certpath:
ssl_keypath:

```
#### group_vars/unifi/vars.yml
```yaml
---
unms_version: 1.1.5

docker_containers:
  unifi:
    description: "Unifi Admin Controller"
    image: linuxserver/unifi-controller:latest
    network_mode: host
    pull: "true"
    ports: []
    volumes:
      - "/etc/localtime:/etc/localtime:ro"
      - "{{ unifi_config_directory }}:/config"
    environment:
      PUID: "0"
      PGID: "0"
  unifi_exporter:
    description: "Prometheus Metrics Collector Unifi"
    image: unifi_exporter
    command: "-config.file /etc/unifi_exporter/config.yml"
    network_mode: host
    volumes:
      - "{{ unifi_exporter_config_directory }}:/etc/unifi_exporter"

docker_compose_projects:
  - project_name: unms
    pull: yes
    definition:
      version: '3.4'
      x-logging: &default-logging
        driver: fluentd
      networks:
        internal:
          driver: bridge
        public:
          driver: bridge
      services:
        fluentd:
          image: "ubnt/unms-fluentd:{{ unms_version }}"
          networks:
            public:
              aliases:
                - unms-fluentd
          ports:
            - "127.0.0.1:{{ unms_fluentd_port }}:{{ unms_fluentd_port }}"
          volumes:
            - "{{ unms_log_directory }}:/fluentd/log"
          environment:
            FLUENTD_UID: "{{ unms_user_id }}"
        redis:
          image: "redis:5.0.5-alpine"
          restart: on-failure
          user: "{{ unms_user_id }}"
          depends_on:
            - fluentd
          networks:
            internal:
              aliases:
                - unms-redis
          volumes:
            - "{{ unms_redis_directory }}:/data/db"
          logging:
            << : *default-logging
            options:
              fluentd-async-connect: "true"
              tag: unms-redis
          command: "redis-server --appendonly yes --dir /data/db/"
        postgres:
          image: "postgres:9.6.12-alpine"
          restart: on-failure
          user: "{{ unms_user_id }}"
          command: postgres -c log_min_duration_statement=500 -c deadlock_timeout=5000
          depends_on:
            - fluentd
          networks:
            internal:
              aliases:
                - unms-postgres
          volumes:
            - "{{ unms_pgconf_directory }}:/docker-entrypoint-initdb.d"
            - "{{ unms_postgres_directory }}:{{ unms_pgdata }}"
          logging:
            << : *default-logging
            options:
              fluentd-async-connect: "true"
              tag: unms-postgres
          environment:
            POSTGRES_USER: "{{ unms_admin_postgres_user }}"
            POSTGRES_PASSWORD: "{{ unms_admin_postgres_password }}"
            UNMS_POSTGRES_DB: "{{ unms_unms_postgres_db }}"
            UNMS_POSTGRES_SCHEMA: "{{ unms_unms_postgres_schema }}"
            UNMS_POSTGRES_USER: "{{ unms_unms_postgres_user }}"
            UNMS_POSTGRES_PASSWORD: "{{ unms_unms_postgres_password }}"
            UCRM_POSTGRES_DB: "{{ unms_ucrm_postgres_db }}"
            UCRM_POSTGRES_SCHEMA: "{{ unms_ucrm_postgres_schema }}"
            UCRM_POSTGRES_USER: "{{ unms_ucrm_postgres_user }}"
            UCRM_POSTGRES_PASSWORD: "{{ unms_ucrm_postgres_password }}"
            PGDATA: "{{ unms_pgdata }}"
        rabbitmq:
          image: "rabbitmq:3.7.14-alpine"
          restart: on-failure
          user: "{{ unms_user_id }}"
          depends_on:
            - fluentd
          networks:
            internal:
              aliases:
                - unms-rabbitmq
          hostname: rabbitmq
          volumes:
            - "{{ unms_rabbitmq_directory }}:/var/lib/rabbitmq"
          logging:
            << : *default-logging
            options:
              fluentd-async-connect: "true"
              tag: unms-rabbitmq
          environment:
            RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS: "{{ unms_rabbitmq_server_additional_erl_args }}"
        unms:
          image: "ubnt/unms:{{ unms_version }}"
          restart: on-failure
          depends_on:
            - fluentd
            - redis
            - postgres
            - rabbitmq
            - nginx
            - ucrm
          networks:
            - public
            - internal
          volumes:
            - "{{ unms_data_directory }}/:/home/app/unms/data"
            - "{{ unms_yarn_directory }}:/home/app/.yarn"
          logging:
            << : *default-logging
            options:
              fluentd-async-connect: "true"
              tag: unms
          environment:
            UNMS_USER_ID: "{{ unms_user_id }}"
            DEMO: "{{ unms_demo }}"
            NODE_ENV: "{{ unms_node_env }}"
            HTTP_PORT: "{{ unms_http_port }}"
            WS_PORT: "{{ unms_ws_port }}"
            WS_SHELL_PORT: "{{ unms_ws_shell_port }}"
            UNMS_WS_API_PORT: "{{ unms_ws_api_port }}"
            UNMS_NETFLOW_PORT: "{{ unms_netflow_port }}"
            SSL_CERT: "{{ unms_ssl_cert }}"
            PUBLIC_HTTPS_PORT: "{{ unms_public_https_port }}"
            PUBLIC_WS_PORT: "{{ unms_public_ws_port }}"
            NGINX_HTTPS_PORT: "{{ unms_nginx_https_port }}"
            NGINX_WS_PORT: "{{ unms_public_ws_port }}"
            SUSPEND_PORT: "{{ unms_suspend_port }}"
            HOST_TAG: "{{ unms_host_tag }}"
            BRANCH: "{{ unms_branch }}"
            HTTP_PROXY: "{{ unms_http_proxy }}"
            HTTPS_PROXY: "{{ unms_https_proxy }}"
            NO_PROXY: "{{ unms_no_proxy }}"
            http_proxy: "{{ unms_http_proxy }}"
            https_proxy: "{{ unms_https_proxy }}"
            no_proxy: "{{ unms_no_proxy }}"
            SECURE_LINK_SECRET: "{{ unms_secure_link_secret }}"
            CLUSTER_SIZE: "{{ unms_cluster_size }}"
            UNMS_PG_PASSWORD: "{{ unms_unms_postgres_password }}"
            UNMS_PG_USER: "{{ unms_unms_postgres_user }}"
            UNMS_PG_DB: "{{ unms_unms_postgres_db }}"
            UNMS_PG_SCHEMA: "{{ unms_unms_postgres_schema }}"
            UNMS_TOKEN: "{{ unms_token }}"
            UNMS_DEPLOYMENT: "{{ unms_deployment }}"
            UNMS_FEATURES: "{{ unms_features }}"
            USE_LOCAL_DISCOVERY: "{{ unms_use_local_discovery }}"
          cap_add:
            - NET_ADMIN
        ucrm:
          image: "ubnt/unms-crm:3.1.2"
          restart: on-failure
          volumes:
            - "{{ unms_ucrm_directory }}:/data"
          command: server_with_migrate
          depends_on:
            - fluentd
            - postgres
            - rabbitmq
            - nginx
          networks:
            - public
            - internal
          logging:
            << : *default-logging
            options:
              fluentd-async-connect: "true"
              tag: ucrm
          environment:
            POSTGRES_HOST: "{{ unms_postgres_host }}"
            POSTGRES_PASSWORD: "{{ unms_ucrm_postgres_password }}"
            POSTGRES_SCHEMA: "{{ unms_ucrm_postgres_schema }}"
            POSTGRES_USER: "{{ unms_ucrm_postgres_user }}"
            POSTGRES_DB: "{{ unms_ucrm_postgres_db }}"
            MAILER_ADDRESS: "{{ unms_mailer_address }}"
            MAILER_ADDRESS_USERNAME: "{{ unms_mailer_address_username }}"
            MAILER_ADDRESS_PASSWORD: "{{ unms_mailer_address_password }}"
            SECRET: "{{ unms_secret }}"
            SUSPEND_PORT: "{{ unms_suspend_port }}"
            PUBLIC_HTTPS_PORT: "{{ unms_public_https_port }}"
            UCRM_USER: "{{ unms_ucrm_user }}"
            UNMS_VERSION: "{{ unms_version }}"
            UNMS_HOST: "{{ unms_host }}"
            UNMS_PORT: "{{ unms_http_port }}"
            UNMS_TOKEN: "{{ unms_token }}"
            UNMS_BASE_URL: "{{ unms_base_url }}"
            UNMS_POSTGRES_SCHEMA: "{{ unms_unms_postgres_schema }}"
        nginx:
          image: "ubnt/unms-nginx:{{ unms_version }}"
          restart: on-failure
          ports:
            - "{{ unms_nginx_http_port }}:{{ unms_nginx_http_port }}"
            - "{{ unms_nginx_https_port }}:{{ unms_nginx_https_port }}"
            - "{{ unms_suspend_port }}:{{ unms_suspend_port }}"
          networks:
            public:
              aliases:
                - unms-nginx
            internal:
              aliases:
                - unms-nginx
          volumes:
            - "{{ unms_cert_directory }}:/cert"
            - "{{ unms_firmware_directory }}:/www/firmwares"
          depends_on:
            - fluentd
          logging:
            << : *default-logging
            options:
              fluentd-async-connect: "true"
              tag: unms-nginx
          environment:
            NGINX_UID: "{{ unms_user_id }}"
            SSL_CERT: "{{ unms_ssl_cert }}"
            SSL_CERT_KEY: "{{ unms_ssl_cert_key }}"
            SSL_CERT_CA: "{{ unms_ssl_cert_ca }}"
            HTTP_PORT: "{{ unms_nginx_http_port }}"
            HTTPS_PORT: "{{ unms_nginx_https_port }}"
            SUSPEND_PORT: "{{ unms_suspend_port }}"
            WS_PORT: "{{ unms_public_ws_port }}"
            UNMS_HTTP_PORT: "{{ unms_http_port }}"
            UNMS_WS_PORT: "{{ unms_ws_port }}"
            UNMS_WS_SHELL_PORT: "{{ unms_ws_shell_port }}"
            UNMS_WS_API_PORT: "{{ unms_ws_api_port }}"
            UNMS_IP_WHITELIST: "{{ unms_ip_whitelist }}"
            PUBLIC_HTTPS_PORT: "{{ unms_public_https_port }}"
            SECURE_LINK_SECRET: "{{ unms_secure_link_secret }}"
        netflow:
          image: "ubnt/unms-netflow:{{ unms_version }}"
          restart: on-failure
          user: "{{ unms_user_id }}"
          ports:
            - "{{ unms_netflow_port }}:{{ unms_netflow_port }}/udp"
          volumes:
            - "/etc/localtime:/etc/localtime:ro"
          networks:
            internal:
              aliases:
                - unms-netflow
            public:
              aliases:
                - unms-netflow
          depends_on:
            - fluentd
            - postgres
            - rabbitmq
            - redis
          logging:
            << : *default-logging
            options:
              fluentd-async-connect: "true"
              tag: unms-netflow
          environment:
            UNMS_NETFLOW_PORT: "{{ unms_netflow_port }}"
            UNMS_PG_PASSWORD: "{{ unms_unms_postgres_password}}"
            UNMS_PG_USER: "{{ unms_unms_postgres_user }}"
            UNMS_PG_DB: "{{ unms_unms_postgres_db }}"
            UNMS_PG_SCHEMA: "{{ unms_unms_postgres_schema }}"

docker_build_images:
  unifi_exporter:
    repo: "https://github.com/ajanis/unifi_exporter.git"


```

## Prometheus Exporter

You will need Prometheus set up somewhere to use the Unifi-Exporter.  You may want to look at [This InfluxDB Role](https://github.com/ajanis/ansible-influxdb) for deploying InfluxDB + Prometheus, which also includes the required Prometheus configuration for the Unifi-Exporter.

## Deploying Telegraf
You may also wish to include this [Telegraf](https://github.com/ajanis/ansible-telegraf) role, which will configure the Telegraf service along with the SNMP MIBS + Telegraf config needed for polling Unifi access point metrics.

**NOTE:** You will need InfluxDB set up somewhere to use the Telegraf + SNMP exporter. You may want to look at [This InfluxDB Role](https://github.com/ajanis/ansible-influxdb) for deploying InfluxDB + Prometheus.

### Updated playbook
```yaml
---
- name: Deploy containerized Ubiquiti UNMS Stack and Unifi-Admin Server
  hosts:
    - unifi
    - unms
  remote_user: root
  gather_facts: yes

  vars_files:
    - vault.yml

  tasks:
    - import_role:
        name: common
    - import_role:
        name: openldap
      when:  openldap_server_ip is defined and openldap_server_ip != None
    - import_role:
        name: ceph-fs
      when:
        - shared_storage
        - storage_backend == "cephfs"
    - import_role:
        name: unifi
    - import_role:
        name: docker
      tags:
        - docker
    - import_role:
        name: unifi
        tasks_from: unifi_admin_ssl
    - import_role:
        name: telegraf
      when: "'telegraf' in group_names"
    - setup:

```

### Unifi role group_vars for Telegraf
```yaml
telegraf_plugins_extra:
  - name: docker
    options:
      endpoint: "unix:///var/run/docker.sock"
      timeout: "5s"
      perdevice: "true"
      total: "true"
## EdgeSwitch CPU Utilization
  - name: exec
    options:
      commands:
        - "/etc/telegraf/telegraf.d/scripts/edgeswitch_load.sh 192.168.0.5"
        - "/etc/telegraf/telegraf.d/scripts/edgeswitch_load.sh 192.168.0.6"
        - "/etc/telegraf/telegraf.d/scripts/edgeswitch_load.sh 192.168.0.7"
      timeout: "1s"
      interval: "5s"
      data_format: "influx"
## Ubiquiti AP Devices
  - name: snmp
    options:
      name: "snmp.UAP"
      agents:
        - "192.168.0.101"
        - "192.168.0.102"
        - "192.168.0.104"
      interval: "10s"
      timeout: "10s"
      retries: 3
      version: 2
      community: "public"
      max_repetitions: 1
  - name: snmp.field
    options:
      is_tag: "true"
      name: "sysName"
      oid: "RFC1213-MIB::sysName.0"
  - name: snmp.field
    options:
      name: "sysObjectID"
      oid: "RFC1213-MIB::sysObjectID.0"
  - name: snmp.field
    options:
      name: "sysDescr"
      oid: "RFC1213-MIB::sysDescr.0"
  - name: snmp.field
    options:
      name: "sysContact"
      oid: "RFC1213-MIB::sysContact.0"
  - name: snmp.field
    options:
      name: "sysLocation"
      oid: "RFC1213-MIB::sysLocation.0"
  - name: snmp.field
    options:
      name: "sysUpTime"
      oid: "RFC1213-MIB::sysUpTime.0"
  - name: snmp.field
    options:
      name: "unifiApSystemModel"
      oid: "UBNT-UniFi-MIB::unifiApSystemModel"
  - name: snmp.field
    options:
      name: "unifiApSystemVersion"
      oid: "UBNT-UniFi-MIB::unifiApSystemVersion"
  - name: snmp.field
    options:
      name: "memTotal"
      oid: "FROGFOOT-RESOURCES-MIB::memTotal.0"
  - name: snmp.field
    options:
      name: "memFree"
      oid: "FROGFOOT-RESOURCES-MIB::memFree.0"
  - name: snmp.field
    options:
      name: "memBuffer"
      oid: "FROGFOOT-RESOURCES-MIB::memBuffer.0"
  - name: snmp.field
    options:
      name: "memCache"
      oid: "FROGFOOT-RESOURCES-MIB::memCache.0"
  - name: snmp.table
    options:
      oid: "IF-MIB::ifTable"
  - name: snmp.table.field
    options:
      is_tag: "true"
      oid: "IF-MIB::ifDescr"
  - name: snmp.table
    options:
      oid: "UBNT-UniFi-MIB::unifiRadioTable"
  - name: snmp.table.field
    options:
      is_tag: "true"
      oid: "UBNT-UniFi-MIB::unifiRadioName"
  - name: snmp.table.field
    options:
      is_tag: "true"
      oid: "UBNT-UniFi-MIB::unifiRadioRadio"
  - name: snmp.table
    options:
      oid: "UBNT-UniFi-MIB::unifiVapTable"
  - name: snmp.table.field
    options:
      is_tag: "true"
      oid: "UBNT-UniFi-MIB::unifiVapName"
  - name: snmp.table.field
    options:
      is_tag: "true"
      oid: "UBNT-UniFi-MIB::unifiVapRadio"
  - name: snmp.table
    options:
      oid: "UBNT-UniFi-MIB::unifiIfTable"
  - name: snmp.table.field
    options:
      is_tag: "true"
      oid: "UBNT-UniFi-MIB::unifiIfName"
  - name: snmp.table
    options:
      oid: "FROGFOOT-RESOURCES-MIB::loadTable"
  - name: snmp.table.field
    options:
      is_tag: "true"
      oid: "FROGFOOT-RESOURCES-MIB::loadDescr"
  - name: snmp.field
    options:
      name: "snmpInPkts"
      oid: "SNMPv2-MIB::snmpInPkts.0"
  - name: snmp.field
    options:
      name: "snmpInGetRequests"
      oid: "SNMPv2-MIB::snmpInGetRequests.0"
  - name: snmp.field
    options:
      name: "snmpInGetNexts"
      oid: "SNMPv2-MIB::snmpInGetNexts.0"
  - name: snmp.field
    options:
      name: "snmpInTotalReqVars"
      oid: "SNMPv2-MIB::snmpInTotalReqVars.0"
  - name: snmp.field
    options:
      name: "snmpInGetResponses"
      oid: "SNMPv2-MIB::snmpInGetResponses.0"
  - name: snmp.field
    options:
      name: "snmpOutPkts"
      oid: "SNMPv2-MIB::snmpOutPkts.0"
  - name: snmp.field
    options:
      name: "snmpOutGetRequests"
      oid: "SNMPv2-MIB::snmpOutGetRequests.0"
  - name: snmp.field
    options:
      name: "snmpOutGetNexts"
      oid: "SNMPv2-MIB::snmpOutGetNexts.0"
  - name: snmp.field
    options:
      name: "snmpOutGetResponses"
      oid: "SNMPv2-MIB::snmpOutGetResponses.0"
## EdgeRouter devices
  - name: snmp
    options:
      name: "snmp.EdgeOS"
      agents:
        - "192.168.0.5"
        - "192.168.0.6"
        - "192.168.0.7"
      interval: "30s"
      timeout: "15s"
      retries: 3
      version: 2
      community: "public"
      max_repetitions: 1
      fielddrop:
        - "laErrorFlag"
        - "laErrMessage"
#      tagdrop:
#        diskIODevice:
#          - "loop*"
#          - "ram*"
  - name: snmp.field
    options:
      name: "sysName"
      oid: "SNMPv2-MIB::sysName.0"
      is_tag: "true"
  #  System vendor OID
  - name: snmp.field
    options:
      name: "sysObjectID"
      oid: "SNMPv2-MIB::sysObjectID.0"
  #  System description
  - name: snmp.field
    options:
      name: "sysDescr"
      oid: "ENTITY-MIB::entPhysicalModelName.2"
  #  System Firmware
  - name: snmp.field
    options:
      name: "emSoftwareRev"
      oid: "ENTITY-MIB::entPhysicalSoftwareRev.1"
  #  System Serial
  - name: snmp.field
    options:
      name: "emSerialNum"
      oid: "ENTITY-MIB::entPhysicalSerialNum.1"
  ## Host/System Resources
  #  System uptime
  - name: snmp.field
    options:
      name: "sysUpTime"
      oid: "iso.3.6.1.2.1.1.3.0"

  ## System Memory (physical/virtual)

  # Total Mem
  - name: snmp.field
    options:
      name: "fpMemAvailable"
      oid: "1.3.6.1.4.1.4413.1.1.1.1.4.2.0"
  # Free Mem
  - name: snmp.field
    options:
      name: "fpMemFree"
      oid: "1.3.6.1.4.1.4413.1.1.1.1.4.1.0"

  ## Interface metrics
  #  Per-interface traffic, errors, drops
  - name: snmp.table
    options:
      oid: "IF-MIB::ifTable"
  - name: snmp.table.field
    options:
      oid: "IF-MIB::ifName"
      is_tag: "true"
  - name: snmp.table
    options:
      oid: "IF-MIB::ifXTable"
  - name: snmp.table.field
    options:
      oid: "IF-MIB::ifAlias"
      is_tag: "true"
  - name: snmp.table.field
    options:
      oid: "IF-MIB::ifName"
      is_tag: "true"

  ## SNMP metrics
  #  Number of SNMP messages received
  - name: snmp.field
    options:
      name: "snmpInPkts"
      oid: "SNMPv2-MIB::snmpInPkts.0"
  #  Number of SNMP Get-Request received
  - name: snmp.field
    options:
      name: "snmpInGetRequests"
      oid: "SNMPv2-MIB::snmpInGetRequests.0"
  #  Number of SNMP Get-Next received
  - name: snmp.field
    options:
      name: "snmpInGetNexts"
      oid: "SNMPv2-MIB::snmpInGetNexts.0"
  #  Number of SNMP objects requested
  - name: snmp.field
    options:
      name: "snmpInTotalReqVars"
      oid: "SNMPv2-MIB::snmpInTotalReqVars.0"
  #  Number of SNMP Get-Response received
  - name: snmp.field
    options:
      name: "snmpInGetResponses"
      oid: "SNMPv2-MIB::snmpInGetResponses.0"
  #  Number of SNMP messages sent
  - name: snmp.field
    options:
      name: "snmpOutPkts"
      oid: "SNMPv2-MIB::snmpOutPkts.0"
  #  Number of SNMP Get-Request sent
  - name: snmp.field
    options:
      name: "snmpOutGetRequests"
      oid: "SNMPv2-MIB::snmpOutGetRequests.0"
  #  Number of SNMP Get-Next sent
  - name: snmp.field
    options:
      name: "snmpOutGetNexts"
      oid: "SNMPv2-MIB::snmpOutGetNexts.0"
  #  Number of SNMP Get-Response sent
  - name: snmp.field
    options:
      name: "snmpOutGetResponses"
      oid: "SNMPv2-MIB::snmpOutGetResponses.0"
```
