# securebank_projeet
un travail pratique en advanced cryptography, qui met en action un Red team, un Blue team chacun avec son rôle comme indique son nom. trois machines virtuelles mises en action
# SecureBank — Final Project
## Structure du dossier

```
securebank_project/
│
├── Guide_SecureBank_Complet.md         ← Guide principal (lire en premier)
│
└── scripts/
    ├── ubuntu_server/
    │   ├── app.py                      ← Application Flask vulnérable
    │   ├── setup_db.sh                 ← Création base de données SQLite
    │   └── setup_https.sh              ← Génération certificat + config Apache
    │
    ├── blue_team/
    │   ├── setup_iptables.sh           ← Règles pare-feu iptables
    │   ├── setup_zfs_snapshots.sh      ← Snapshots automatiques ZFS
    │   └── local.rules                 ← Règles Suricata IDS
    │
    └── red_team/
        └── ransom_demo.ps1             ← Script ransomware démo (Windows)
```

## Comment utiliser ce projet

1. **Lire d'abord** : `Guide_SecureBank_Complet.md`
2. **Ubuntu Server** : exécuter les scripts dans `scripts/ubuntu_server/`
3. **Blue Team** : appliquer les défenses dans `scripts/blue_team/`
4. **Red Team** : utiliser les outils Kali + le script dans `scripts/red_team/`

## Ordre d'exécution recommandé

```
Phase 1 : setup_db.sh → app.py → setup_https.sh
Phase 2 : setup_iptables.sh → local.rules → setup_zfs_snapshots.sh
Phase 3 : Attaques Red Team (Kali Linux)
Phase 4 : Rapport + Présentation
```

> ⚠️ AVERTISSEMENT : Tous les scripts sont à usage exclusivement pédagogique
> dans un environnement isolé VirtualBox. Ne jamais utiliser sur des systèmes réels.
