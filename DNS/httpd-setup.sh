#!/bin/bash

set -euo pipefail

# Vérifie si l'utilisateur est root
if [ "$EUID" -ne 0 ]; then
    echo "Ce script doit être exécuté en tant que root."
    exit 1
fi

# === INSTALLATION ===
sudo dnf install httpd -y

# === CONFIGURATION ===
base_domain=$(sed -n '1p' /config_dns.txt | sed 's/^"\(.*\)"$/\1/')  # Récupérer la première ligne
zone_directe=$(sed -n '2p' /config_dns.txt | sed 's/^"\(.*\)"$/\1/')  # Récupérer la deuxième ligne
zone_inverse=$(sed -n '3p' /config_dns.txt | sed 's/^"\(.*\)"$/\1/')  # Récupérer la troisième ligne

# Afficher les variables pour vérification
echo "Base domain : $base_domain"
echo "Zone directe : $zone_directe"
echo "Zone inverse : $zone_inverse"

# === SAISIE UTILISATEUR ===
user="$1"
read -p "Adresse IP à associer (ex: 10.42.0.15) : " ip

# === CONSTRUCTION DU NOM DE DOMAINE ===
domain="${user}.${base_domain}"
ip_last_octet=$(echo "$ip" | awk -F. '{print $4}')

# === CRÉATION DU DOSSIER WEB ===
mkdir -p /var/www/$domain/public_html

cat > /var/www/$domain/public_html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Bienvenue sur $domain</title>
</head>
<body>
    <h1>Site de $domain opérationnel !</h1>
</body>
</html>
EOF

# === CONFIGURATION DU VIRTUALHOST APACHE ===
conf_file="/etc/httpd/conf.d/$domain.conf"

cat > "$conf_file" <<EOF
<VirtualHost *:80>
    ServerName $domain
    ServerAlias www.$domain
    DocumentRoot /var/www/$domain/public_html
    <Directory /var/www/$domain/public_html>
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog /var/log/httpd/$domain-error.log
    CustomLog /var/log/httpd/$domain-access.log combined
</VirtualHost>
EOF

chown -R apache:apache /var/www/$domain/public_html
chmod -R 755 /var/www/$domain

# === AJOUT DANS LA ZONE DIRECTE ===
echo -e "\n; Ajout automatique pour $domain\n$user    IN      A       $ip" >> "$zone_directe"

# === AJOUT DANS LA ZONE INVERSE ===
echo -e "\n; Ajout automatique pour $ip ($domain)\n$ip_last_octet    IN      PTR     $domain." >> "$zone_inverse"

# === INCRÉMENTATION DU SERIAL ===
increment_serial() {
    zone_file="$1"
    current_serial=$(grep -E '^[ \t]*[0-9]{10}[ \t]*;[ \t]*Serial' "$zone_file" | awk '{print $1}')
    if [ -z "$current_serial" ]; then
        echo "Serial introuvable dans $zone_file, skipping..."
        return
    fi
    new_serial=$((current_serial + 1))
    sed -i "s/$current_serial[ \t]*;[ \t]*Serial/$new_serial ; Serial/" "$zone_file"
}

increment_serial "$zone_directe"
increment_serial "$zone_inverse"

# === RECHARGEMENT DE BIND ET HTTPD ===
echo "Rechargement de BIND et Apache..."
rndc reload
systemctl restart httpd

# === FIREWALL ===
firewall-cmd --permanent --add-service=http
firewall-cmd --reload

echo "Le site $domain est prêt avec l'IP $ip. DNS et Apache sont configurés."
