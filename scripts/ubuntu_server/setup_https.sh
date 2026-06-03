#!/bin/bash
# ============================================================
# SCRIPT GÉNÉRATION CERTIFICAT HTTPS AUTO-SIGNÉ
# À exécuter sur Ubuntu Server (192.168.100.20)
# ============================================================

echo "[*] Création du répertoire SSL ..."
sudo mkdir -p /etc/ssl/bank
cd /etc/ssl/bank

echo "[*] Génération de la clé privée de la CA (4096 bits) ..."
sudo openssl genrsa -out ca.key 4096

echo "[*] Création du certificat CA auto-signé ..."
sudo openssl req -new -x509 -days 365 -key ca.key -out ca.crt \
  -subj "/C=CM/ST=Centre/L=Yaounde/O=SecureBank/CN=SecureBank-CA"

echo "[*] Génération de la clé privée du serveur (2048 bits) ..."
sudo openssl genrsa -out server.key 2048

echo "[*] Création de la demande de signature CSR ..."
sudo openssl req -new -key server.key -out server.csr \
  -subj "/C=CM/ST=Centre/L=Yaounde/O=SecureBank/CN=192.168.100.20"

echo "[*] Signature du certificat par la CA ..."
sudo openssl x509 -req -days 365 -in server.csr \
  -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt

echo "[+] Certificats générés :"
ls -la /etc/ssl/bank/

echo "[*] Configuration Apache HTTPS ..."
sudo tee /etc/apache2/sites-available/bank-ssl.conf > /dev/null <<'EOF'
<VirtualHost *:443>
    ServerName 192.168.100.20
    SSLEngine on
    SSLCertificateFile    /etc/ssl/bank/server.crt
    SSLCertificateKeyFile /etc/ssl/bank/server.key

    # HSTS — Empêche le SSL stripping
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"

    ProxyPass / http://localhost:5000/
    ProxyPassReverse / http://localhost:5000/
</VirtualHost>
EOF

echo "[*] Activation des modules Apache ..."
sudo a2enmod ssl headers proxy proxy_http
sudo a2ensite bank-ssl
sudo systemctl restart apache2

echo "[+] HTTPS configuré avec HSTS activé !"
echo "[+] Accès : https://192.168.100.20"
