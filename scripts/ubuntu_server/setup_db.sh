#!/bin/bash
# ============================================================
# SCRIPT DE CRÉATION DE LA BASE DE DONNÉES SECUREBANK
# À exécuter sur Ubuntu Server (192.168.100.20)
# ============================================================

echo "[*] Création du répertoire /var/www/bank ..."
sudo mkdir -p /var/www/bank
cd /var/www/bank

echo "[*] Création de la base de données SQLite avec faux clients ..."
sqlite3 db.sqlite <<EOF
CREATE TABLE IF NOT EXISTS accounts (
    id INTEGER PRIMARY KEY,
    customer_name TEXT,
    email TEXT,
    balance REAL,
    password_hash TEXT
);
INSERT OR IGNORE INTO accounts VALUES (1,'Alice Martin','alice@securebank.cm',5000.00,'5f4dcc3b5aa765d61d8327deb882cf99');
INSERT OR IGNORE INTO accounts VALUES (2,'Bob Nguyen','bob@securebank.cm',12000.00,'e10adc3949ba59abbe56e057f20f883e');
INSERT OR IGNORE INTO accounts VALUES (3,'Carol Smith','carol@securebank.cm',3200.00,'25f9e794323b453885f5181f1b624d0b');
INSERT OR IGNORE INTO accounts VALUES (4,'David Eto','david@securebank.cm',8700.00,'8d3533d75ae2c3966d7e0d4fcc69216b');
INSERT OR IGNORE INTO accounts VALUES (5,'Eve Biya','eve@securebank.cm',15000.00,'96e79218965eb72c92a549dd5a330112');
EOF

echo "[+] Base de données créée : /var/www/bank/db.sqlite"
echo "[+] 5 faux clients insérés"
sqlite3 db.sqlite "SELECT id, customer_name, balance FROM accounts;"
