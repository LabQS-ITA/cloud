FROM ubuntu:focal

RUN ENV DEBIAN_FRONTEND=noninteractive && \
        apt-get update && \ 
        apt-get upgrade -y && \
        apt-get install -y wget gnupg curl openjdk-11-jdk mysql-server && \ 
        wget -O - http://download.cloudstack.org/release.asc | apt-key add - && \
        echo deb http://download.cloudstack.org/ubuntu focal 4.17 | tee -a /etc/apt/sources.list.d/cloudstack.list && \ 
        apt-get update && \ 
        apt-get install -y cloudstack-management cloudstack-agent cloudstack-usage && \ 
        systemctl stop cloudstack-agent.service cloudstack-management.service cloudstack-usage.service

COPY cloudstack.cnf /etc/mysql/conf.d/cloudstack.cnf

RUN systemctl restart mysql.service

RUN cloudstack-setup-databases maint:'c0r0n@'@localhost --deploy-as=root -m 'c0r0n@' -k 'c0r0n@' -i 127.0.0.1 && \
        cloudstack-setup-management
