#!/bin/bash

# Vérification des droits root
if [ "$EUID" -ne 0 ]; then
  echo "Ce script doit être exécuté en tant que root"
  exit 1
fi

# Demande du nom de domaine et de l'adresse IP
read -p "Nom du domaine (ex : exemple.lan) : " DOMAIN
read -p "Adresse IP du serveur DNS (ex : 192.168.1.10) : " IP

# Traitement des variables
ZONE_FILE="/var/named/${DOMAIN}.zone"
REV_FILE="/var/named/$(echo $IP | awk -F. '{print $3"."$2"."$1}').rev"
REV_ZONE="$(echo $IP | awk -F. '{print $3"."$2"."$1}').in-addr.arpa"
LAST_OCTET=$(echo $IP | awk -F. '{print $4}')
SERIAL=$(date +%Y%m%d01)

# Installation de BIND
dnf install bind bind-utils -y

sudo truncate -s 0 /etc/named.conf


cat <<EOF > /etc/named.conf
options {
    listen-on port 53 { any; };
    directory "/var/named";
    dump-file "/var/named/data/cache_dump.db";
    statistics-file "/var/named/data/named_stats.txt";
    memstatistics-file "/var/named/data/named_mem_stats.txt";
    allow-query { any; };
};
EOF
# Configuration principale de named
cat <<EOF >> /etc/named.conf

zone "$DOMAIN" IN {
    type master;
    file "$ZONE_FILE";
};


zone "$REV_ZONE" IN {
    type master;
    file "$REV_FILE";
};
EOF


#enregistrement de la configuration

echo "$DOMAIN" > /config_dns.txt
echo "$ZONE_FILE" >> /config_dns.txt
echo "$REV_FILE" >> /config_dns.txt

# Création de la zone directe
cat <<EOF > "$ZONE_FILE"
\$TTL 86400
@ IN SOA ns1.${DOMAIN}. root.${DOMAIN}. (
    $SERIAL ; Serial
    3600 ; Refresh
    1800 ; Retry
    604800 ; Expire
    86400 ) ; Minimum

@   IN NS ns1.${DOMAIN}.
@   IN A $IP
ns1 IN A $IP
www IN A $IP
EOF

# Création de la zone inverse
cat <<EOF > "$REV_FILE"
\$TTL 86400
@ IN SOA ns1.${DOMAIN}. root.${DOMAIN}. (
    $SERIAL ; Serial
    3600 ; Refresh
    1800 ; Retry
    604800 ; Expire
    86400 ) ; Minimum

@ IN NS ns1.${DOMAIN}.
$LAST_OCTET IN PTR ns1.${DOMAIN}.
$LAST_OCTET IN PTR www.${DOMAIN}.
EOF

# Activation et configuration du pare-feu
systemctl enable --now named
firewall-cmd --permanent --add-service=dns
firewall-cmd --permanent --add-port=53/udp
firewall-cmd --permanent --add-port=53/tcp
firewall-cmd --reload

echo "Configuration terminée pour le domaine $DOMAIN avec IP $IP"
