# Ansible role for Unifi Admin service with metrics provided by Prometheus and Telegraf + InfluxDB
This role makes use of [This Docker Role](https://github.com/ajanis/ansible-docker) to deploy the Ubiquiti Unifi Admin service along with a Prometheus metrics exporter container and the Telegraf metrics collector along with required SNMP MIBS/configurations.

## Example using group_vars
This is an example of how to use this role to deploy the Ubiquiti Unifi Admin controller and a Prometheus metrics collector for Unifi Admin

### docker_containers and docker_build_images group_vars for Unifi Admin and Unifi-Exporter
Calls the docker role with the following group_vars to build a docker image from the specified git repo and deploy the containerized service and systemd configs.

#### group_vars/unifi/vars.yml
```
docker_containers: 
  unifi:
    description: "Unifi Admin Controller"
    image: linuxserver/unifi:unstable
    network_mode: host
    ports: []
    volumes:
      - '{{ data_mount_root }}/{{ configs_directory }}/unifi:/config'
    env:
      PUID: '0'
      PGID: '0'
  unifi_exporter:
    description: "Prometheus Metrics Collector Unifi"
    image: unifi_exporter
    command: "-config.file /etc/unifi_exporter/config.yml"
    network_mode: host
    volumes:
      - '{{ data_mount_root }}/{{ configs_directory }}/unifi_exporter:/etc/unifi_exporter'
      
docker_build_images:
  unifi_exporter:
    repo: "https://github.com/mdlayher/unifi_exporter.git"
```

## Prometheus Exporter

You will need Prometheus set up somewhere to use the Unifi-Exporter.  You may want to look at [This InfluxDB Role](https://github.com/ajanis/ansible-influxdb) for deploying InfluxDB + Prometheus, which also includes the required Prometheus configuration for the Unifi-Exporter.

## Deploying Telegraf
You may also wish to include this [Telegraf](https://github.com/ajanis/ansible-telegraf) role, which will configure the Telegraf service along with the SNMP MIBS + Telegraf config needed for polling Unifi access point metrics.

**NOTE:** You will need InfluxDB set up somewhere to use the Telegraf + SNMP exporter. You may want to look at [This InfluxDB Role](https://github.com/ajanis/ansible-influxdb) for deploying InfluxDB + Prometheus. 

### Updated playbook
```
---
- name: Deploy Unifi Controller
  hosts: unifi
  become: True
  tasks:
    - import_role:
        name: docker
    - import_role:
        name: unifi
    - import_role:
        name: telegraf
```

### Unifi role group_vars for Telegraf
```
telegraf_plugins_extra:
  - name: docker
    options:
      endpoint: "unix:///var/run/docker.sock"
      timeout: "5s"
      perdevice: "true"
      total: "true"
  - name: snmp
    options:
      name: "snmp.UAP"
      agents:
        - "192.168.0.101"
        - "192.168.0.102"
        - "192.168.0.103"
      interval: "10s"
      timeout: "10s"
      retries: 3
      version: 1
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
```




