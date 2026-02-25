# =====================================================================================
# /Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/PODS/PTR/PTR.md
# =====================================================================================
Version: 1.0
Created: 2026-02-02
LastUpdate: ____-__-__
Scope: CLAWBOT PODS (Kubernetes) - Monthly PTR + Rebuild + Uninstall
Host: Mac Studio M3 Ultra - macOS Tahoe

=====================================================================================
FRANÇAIS (FR) — PTR PODS MENSUELLE + DÉPANNAGE + RECONSTRUCTION
=====================================================================================

Règles:
- Ce document est exécuté par un opérateur novice.
- Chaque étape est MANUELLE, SÉQUENTIELLE, avec résultat attendu clair.
- On coche Conforme / Non conforme, on note le résultat obtenu.
- Aucune destruction sans sauvegarde validée.
- Tous les scripts génèrent une trace dans un dossier PTR daté.

Chemins fixes (ne pas modifier):
- REPO: /Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder
- PRODUCTION: /Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION
- PODS: /Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/PODS
- PTR: /Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/PODS/PTR
- SAVE: /Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/PODS/SAVE/SAVE_Clawbot_POD

Dossier de recette mensuelle (créé automatiquement par les scripts):
- /Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/PODS/PTR/PTR_PODS_YYYY-MM-DD
- Exemple: .../PTR/PTR_PODS_2026-02-02

-------------------------------------------------------------------------------------
A) PRÉ-REQUIS (À VÉRIFIER AVANT TOUT)
-------------------------------------------------------------------------------------

Commande (copier-coller):

/bin/zsh -lc 'echo "DATE=$(date +%Y-%m-%d)"; echo "USER=$USER"; echo "SHELL=$SHELL"; echo "PWD=$PWD"; command -v docker; command -v kubectl; command -v multipass; ls -ld "/Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/PODS"'

Résultat attendu:
- Affiche une DATE au format YYYY-MM-DD
- Affiche le chemin de docker, kubectl, multipass (pas vide)
- Le dossier PODS existe (ls -ld réussi)

Conforme: [  ] Oui  [  ] Non
Résultat obtenu (copier/coller ici):
_____________________________________________________________________________________
Observations:
_____________________________________________________________________________________

-------------------------------------------------------------------------------------
B) MAINTENANCE MENSUELLE (SCRIPT DE VÉRIFICATION)
-------------------------------------------------------------------------------------

Script à lancer (copier-coller):
/bin/zsh -lc '/Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/PODS/PTR/verif_mensuelle_pods.sh'

Résultat attendu (minimum):
- Affiche une fin de script sans erreur bloquante
- Crée le dossier: .../PTR/PTR_PODS_YYYY-MM-DD
- Crée au moins ces fichiers dans le dossier du jour:
  - PTR_YYYY-MM-DD_FR.md (ou équivalent)
  - PTR_YYYY-MM-DD_EN.md (ou équivalent)
  - des fichiers d’état (docker/kubeconfig) dans SAVE avec un suffixe de date

Conforme: [  ] Oui  [  ] Non
Résultat obtenu (copier/coller ici):
_____________________________________________________________________________________
Observations:
_____________________________________________________________________________________

-------------------------------------------------------------------------------------
C) SAUVEGARDE (OBLIGATOIRE AVANT DÉSINSTALLATION / RECONSTRUCTION)
-------------------------------------------------------------------------------------

Commande (copier-coller):
/bin/zsh -lc 'ls -la "/Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/PODS/SAVE/SAVE_Clawbot_POD" | head -n 50'

Résultat attendu:
- Liste des fichiers/dossiers de sauvegarde visibles
- Le dossier n’est pas vide après une exécution récente de la vérification mensuelle

Conforme: [  ] Oui  [  ] Non

Résultat obtenu:

_____________________________________________________________________________________
Observations:


_____________________________________________________________________________________


-------------------------------------------------------------------------------------
D) DÉSINSTALLATION (UNIQUEMENT SI INCIDENT CONFIRMÉ)
-------------------------------------------------------------------------------------

Script à lancer (copier-coller):
/bin/zsh -lc '/Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/PODS/desinstallation.sh'

Résultat attendu (minimum):
- Le script crée/complète le dossier PTR du jour: .../PTR/PTR_PODS_YYYY-MM-DD
- Le script écrit un log: .../PTR/PTR_PODS_YYYY-MM-DD/desinstallation.log
- Le script affiche une ligne finale: "DESINSTALLATION_OK"
- Les sauvegardes dans SAVE ne sont pas supprimées

Conforme: [  ] Oui  [  ] Non

Résultat obtenu:

_____________________________________________________________________________________
Observations:


_____________________________________________________________________________________


-------------------------------------------------------------------------------------
E) RECONSTRUCTION / INSTALLATION À L’IDENTIQUE (APRÈS DÉSINSTALLATION OU SUR NOUVEL HÔTE)
-------------------------------------------------------------------------------------

Script à lancer (copier-coller):
/bin/zsh -lc '/Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/PODS/reconstruction.sh'

Résultat attendu (minimum):
- Le script crée/complète le dossier PTR du jour: .../PTR/PTR_PODS_YYYY-MM-DD
- Le script écrit un log: .../PTR/PTR_PODS_YYYY-MM-DD/reconstruction.log
- Le script affiche une ligne finale: "RECONSTRUCTION_OK"
- Les commandes kubectl (dans le log) montrent:
  - kubectl get nodes : au moins 1 noeud, statut Ready
  - kubectl get pods -A : des pods listés (pas vide)

Conforme: [  ] Oui  [  ] Non

Résultat obtenu:

_____________________________________________________________________________________
Observations:


_____________________________________________________________________________________



-------------------------------------------------------------------------------------
F) CONTRÔLE POST-RECONSTRUCTION (MANUEL)
-------------------------------------------------------------------------------------

Commande 1 (copier-coller):
/bin/zsh -lc 'kubectl get nodes -o wide'

Résultat attendu:
- Au moins 1 ligne de noeud
- STATUS = Ready

Conforme: [  ] Oui  [  ] Non

Résultat obtenu:

_____________________________________________________________________________________
Observations:


_____________________________________________________________________________________



_____________________________________________________________________________________

Commande 2 (copier-coller):
/bin/zsh -lc 'kubectl get pods -A'

Résultat attendu:
- Des pods affichés
- Les pods critiques ne sont pas en CrashLoopBackOff (sinon: Non conforme)

Conforme: [  ] Oui  [  ] Non

Résultat obtenu:

_____________________________________________________________________________________
Observations:


_____________________________________________________________________________________



-------------------------------------------------------------------------------------
G) MISE À JOUR PACKAGES (MENSUEL — SANS CHANGER LA CONFIG)
-------------------------------------------------------------------------------------

Commande (copier-coller):
/bin/zsh -lc 'brew update && brew upgrade && brew cleanup -s && softwareupdate -l 2>/dev/null || true; echo "UPDATES_DONE"'

Résultat attendu:
- Fin sans erreur bloquante
- Affiche "UPDATES_DONE"

Conforme: [  ] Oui  [  ] Non

Résultat obtenu:

_____________________________________________________________________________________
Observations:


_____________________________________________________________________________________



-------------------------------------------------------------------------------------
H) CONSIGNATION + SIGNATURES
-------------------------------------------------------------------------------------

Date/Heure de fin (YYYY-MM-DD HH:MM):
____-__-__ __:__

Conclusion globale:

[  ] PTR VALIDÉE
[  ] PTR REFUSÉE



_____________________________________________________________________________________

Opérateur:
Nom:
Signature:


_____________________________________________________________________________________
Observations:


_____________________________________________________________________________________

Vérificateur:
Nom:

Signature:


_____________________________________________________________________________________
Observations:


_____________________________________________________________________________________



=====================================================================================
ENGLISH (EN) — MONTHLY PODS PTR + TROUBLESHOOTING + REBUILD
=====================================================================================

Rules:
- This document is executed by a non-technical operator.
- Each step is MANUAL, SEQUENTIAL, with a clear expected output.
- Tick Pass / Fail and record the actual output.
- No destructive action without a validated backup.
- All scripts generate traces in a dated PTR folder.

Fixed paths (do not change):
- REPO: /Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder
- PRODUCTION: /Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION
- PODS: /Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/PODS
- PTR: /Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/PODS/PTR
- SAVE: /Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/PODS/SAVE/SAVE_Clawbot_POD

Monthly run folder (created automatically by scripts):
- /Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/PODS/PTR/PTR_PODS_YYYY-MM-DD
- Example: .../PTR/PTR_PODS_2026-02-02

-------------------------------------------------------------------------------------
A) PREREQUISITES (CHECK BEFORE ANYTHING)
-------------------------------------------------------------------------------------

Command (copy/paste):
/bin/zsh -lc 'echo "DATE=$(date +%Y-%m-%d)"; echo "USER=$USER"; echo "SHELL=$SHELL"; echo "PWD=$PWD"; command -v docker; command -v kubectl; command -v multipass; ls -ld "/Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/PODS"'

Expected output:
- Shows DATE in YYYY-MM-DD
- Shows docker/kubectl/multipass paths (non-empty)
- PODS folder exists (ls -ld succeeds)

Pass: [  ] Yes  [  ] No

Actual output (paste here):

_____________________________________________________________________________________
Notes:


_____________________________________________________________________________________


-------------------------------------------------------------------------------------
B) MONTHLY MAINTENANCE (VERIFICATION SCRIPT)
-------------------------------------------------------------------------------------

Script to run (copy/paste):
/bin/zsh -lc '/Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/PODS/PTR/verif_mensuelle_pods.sh'

Expected output (minimum):
- Script ends without blocking error
- Creates folder: .../PTR/PTR_PODS_YYYY-MM-DD
- Creates at least these files in today folder:
  - PTR_YYYY-MM-DD_FR.md (or equivalent)
  - PTR_YYYY-MM-DD_EN.md (or equivalent)
  - state files (docker/kubeconfig) in SAVE with a date suffix

Pass: [  ] Yes  [  ] No

Actual output:

_____________________________________________________________________________________
Notes:


_____________________________________________________________________________________


-------------------------------------------------------------------------------------
C) BACKUP (MANDATORY BEFORE UNINSTALL / REBUILD)
-------------------------------------------------------------------------------------

Command (copy/paste):
/bin/zsh -lc 'ls -la "/Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/PODS/SAVE/SAVE_Clawbot_POD" | head -n 50'

Expected output:
- Shows backup files/folders
- Not empty after a recent monthly verification run

Pass: [  ] Yes  [  ] No

Actual output:

_____________________________________________________________________________________
Notes:


_____________________________________________________________________________________


-------------------------------------------------------------------------------------
D) UNINSTALL (ONLY IF INCIDENT CONFIRMED)
-------------------------------------------------------------------------------------

Script to run (copy/paste):
/bin/zsh -lc '/Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/PODS/desinstallation.sh'

Expected output (minimum):
- Creates/appends today PTR folder: .../PTR/PTR_PODS_YYYY-MM-DD
- Writes log: .../PTR/PTR_PODS_YYYY-MM-DD/desinstallation.log
- Prints final line: "DESINSTALLATION_OK"
- Does not delete backups in SAVE

Pass: [  ] Yes  [  ] No

Actual output:

_____________________________________________________________________________________
Notes:


_____________________________________________________________________________________


-------------------------------------------------------------------------------------
E) REBUILD / INSTALL IDENTICALLY (AFTER UNINSTALL OR ON A FRESH HOST)
-------------------------------------------------------------------------------------

Script to run (copy/paste):
/bin/zsh -lc '/Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/PODS/reconstruction.sh'

Expected output (minimum):
- Creates/appends today PTR folder: .../PTR/PTR_PODS_YYYY-MM-DD
- Writes log: .../PTR/PTR_PODS_YYYY-MM-DD/reconstruction.log
- Prints final line: "RECONSTRUCTION_OK"
- kubectl in the log shows:
  - kubectl get nodes: at least 1 node, Ready
  - kubectl get pods -A: pods listed (not empty)

Pass: [  ] Yes  [  ] No

Actual output:

_____________________________________________________________________________________
Notes:


_____________________________________________________________________________________


-------------------------------------------------------------------------------------
F) POST-REBUILD MANUAL CHECK
-------------------------------------------------------------------------------------

Command 1 (copy/paste):
/bin/zsh -lc 'kubectl get nodes -o wide'

Expected output:
- At least 1 node line
- STATUS = Ready

Pass: [  ] Yes  [  ] No

Actual output:

_____________________________________________________________________________________
Notes:


_____________________________________________________________________________________


Command 2 (copy/paste):
/bin/zsh -lc 'kubectl get pods -A'

Expected output:
- Pods displayed
- No critical pods in CrashLoopBackOff (otherwise Fail)

Pass: [  ] Yes  [  ] No

Actual output:

_____________________________________________________________________________________
Notes:


_____________________________________________________________________________________


-------------------------------------------------------------------------------------
G) MONTHLY PACKAGE UPDATES (WITHOUT CHANGING CONFIG)
-------------------------------------------------------------------------------------

Command (copy/paste):
/bin/zsh -lc 'brew update && brew upgrade && brew cleanup -s && softwareupdate -l 2>/dev/null || true; echo "UPDATES_DONE"'

Expected output:
- Ends without blocking error
- Prints "UPDATES_DONE"

Pass: [  ] Yes  [  ] No

Actual output:

_____________________________________________________________________________________
Notes:


_____________________________________________________________________________________


-------------------------------------------------------------------------------------
H) RECORDS + SIGNATURES
-------------------------------------------------------------------------------------

End date/time (YYYY-MM-DD HH:MM):
____-__-__ __:__

Overall result:
[  ] PTR PASSED
[  ] PTR FAILED


Actual output:

_____________________________________________________________________________________

Operator:
Name:

Signature:

_____________________________________________________________________________________

Notes:


_____________________________________________________________________________________


Verifier:
Name:

Signature:

_____________________________________________________________________________________

Notes:


_____________________________________________________________________________________


