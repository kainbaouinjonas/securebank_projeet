#!/bin/bash
# ============================================================
# SCRIPT IPTABLES — BLUE TEAM SECUREBANK
# À exécuter sur Ubuntu Server (192.168.100.20)
# ============================================================

echo "[*] Réinitialisation des règles iptables ..."
sudo iptables -F
sudo iptables -X
sudo iptables -Z

echo "[*] Politique par défaut : tout bloquer en entrée ..."
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

echo "[*] Autoriser loopback (communications internes) ..."
sudo iptables -A INPUT -i lo -j ACCEPT

echo "[*] Autoriser connexions déjà établies ..."
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

echo "[*] Autoriser SSH (port 22) ..."
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

echo "[*] Autoriser HTTPS (port 443) ..."
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT

echo "[*] Autoriser OpenVPN (port UDP 1194) ..."
sudo iptables -A INPUT -p udp --dport 1194 -j ACCEPT

echo "[*] BLOQUER SMB depuis l'IP de Kali (192.168.100.10) ..."
sudo iptables -A INPUT -s 192.168.100.10 -p tcp --dport 445 -j DROP
sudo iptables -A INPUT -s 192.168.100.10 -p udp --dport 445 -j DROP

echo "[*] Logger les paquets bloqués ..."
sudo iptables -A INPUT -j LOG --log-prefix "IPTABLES-BLOCKED: " --log-level 4

echo "[*] Sauvegarder les règles (persistent après reboot) ..."
sudo netfilter-persistent save

echo ""
echo "[+] Règles iptables appliquées avec succès !"
echo "[+] Résumé des règles :"
sudo iptables -L INPUT -v --line-numbers
