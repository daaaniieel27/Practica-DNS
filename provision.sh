#!/usr/bin/bash

DEBIAN_FRONTEND=noninteractive
CONFIG_DIR="/vagrant/config"

# install dependencies
apt update -y >/dev/null 2>&1
apt install bind9 bind9utils bind9-doc -y >/dev/null 2>&1

# set the default DNS and default start bind command
cp ${CONFIG_DIR}/resolv.conf /etc/resolv.conf
cp ${CONFIG_DIR}/named /etc/default

# check if we are on tierra or venus before copying files
if [ $(cat /etc/hostname) == "tierra" ]; then
    cp ${CONFIG_DIR}/tierra/named.conf.options /etc/bind
    cp ${CONFIG_DIR}/tierra/named.conf.local /etc/bind
    cp ${CONFIG_DIR}/tierra/db.sistema.sol. /var/lib/bind
    cp ${CONFIG_DIR}/tierra/sistema.sol.rev /var/lib/bind
else
    cp ${CONFIG_DIR}/venus/named.conf.local /etc/bind
    cp ${CONFIG_DIR}/venus/named.conf.options /etc/bind
fi

# restart the service to apply all changes
systemctl restart named