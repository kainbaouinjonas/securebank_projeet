#!/bin/bash
# ============================================================
# SCRIPT ZFS SNAPSHOTS — BLUE TEAM SECUREBANK
# À exécuter sur Ubuntu Server (192.168.100.20)
# ============================================================

echo "[*] Installation de ZFS ..."
sudo apt install zfsutils-linux -y

echo "[*] Création du pool ZFS (adapter /dev/sdb selon votre config) ..."
# IMPORTANT : remplacer /dev/sdb par votre disque disponible
# Vérifier avec : lsblk
sudo zpool create bankpool /dev/sdb

echo "[*] Création du dataset pour les données bancaires ..."
sudo zfs create bankpool/bankdata

echo "[*] Copie des données bancaires dans ZFS ..."
sudo cp -r /var/www/bank/* /bankpool/bankdata/

echo "[*] Premier snapshot manuel ..."
SNAP_NAME="bankpool/bankdata@initial-$(date +%Y%m%d-%H%M)"
sudo zfs snapshot "$SNAP_NAME"
echo "[+] Snapshot créé : $SNAP_NAME"

echo "[*] Configuration des snapshots automatiques toutes les heures ..."
CRON_LINE='0 * * * * root /sbin/zfs snapshot bankpool/bankdata@auto-$(date +\%Y\%m\%d-\%H\%M)'
echo "$CRON_LINE" | sudo tee -a /etc/crontab

echo ""
echo "[+] Configuration ZFS terminée !"
echo "[+] Snapshots disponibles :"
sudo zfs list -t snapshot

echo ""
echo "--- COMMANDES UTILES ---"
echo "Lister snapshots   : sudo zfs list -t snapshot"
echo "Nouveau snapshot   : sudo zfs snapshot bankpool/bankdata@mon-backup"
echo "Restaurer          : sudo zfs rollback bankpool/bankdata@NOM_DU_SNAPSHOT"
echo "Supprimer snapshot : sudo zfs destroy bankpool/bankdata@NOM_DU_SNAPSHOT"
