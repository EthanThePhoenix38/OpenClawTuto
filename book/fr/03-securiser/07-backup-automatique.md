# 🎯 3.7 - Backup Automatique

## 📋 Ce que tu vas apprendre

- Sauvegarder automatiquement Phoenix
- Restaurer en cas de problème
- Configurer des backups incrémentaux
- Tester tes sauvegardes

## 🛠️ Prérequis

- [Chapitre 3.6](./06-monitoring-alertes.md) complété
- k3s opérationnel
- Phoenix déployé

---

## 📝 Étapes détaillées

### Étape 1 : Comprendre ce qu'il faut sauvegarder

**Pourquoi ?** Tu ne veux pas tout perdre si quelque chose casse.

**Ce qu'il faut sauvegarder :**

```
┌─────────────────────────────────────────────────────────────────┐
│                    DONNÉES À SAUVEGARDER                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  🔴 CRITIQUE (perte = catastrophe)                              │
│  ├── ~/.phoenix/phoenix.json (configuration)                  │
│  ├── ~/.phoenix/credentials/ (authentification)                │
│  └── ~/.phoenix/agents/*/sessions/ (conversations)             │
│                                                                 │
│  🟠 IMPORTANT (perte = embêtant)                                │
│  ├── Kubernetes Secrets (API keys)                              │
│  ├── ConfigMaps (configs)                                       │
│  └── PersistentVolumes (données)                                │
│                                                                 │
│  🟢 FACULTATIF (perte = pas grave)                              │
│  ├── Logs (peuvent être regénérés)                              │
│  └── Cache (se reconstruit)                                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Étape 2 : Créer le script de backup

**Pourquoi ?** Un script automatise tout le processus.

**Comment ?**

```bash
cat << 'EOFSCRIPT' > ~/scripts/backup-phoenix.sh
#!/bin/bash
# =============================================================================
# Script de backup Phoenix
# Version: 1.0.0
# Auteur: Ethan Bernier
# ORCID: 0009-0008-9839-5763
# =============================================================================

set -euo pipefail

# Configuration
BACKUP_DIR="${HOME}/backups/phoenix"
PHOENIX_DIR="${HOME}/.phoenix"
RETENTION_DAYS=30
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="phoenix_backup_${DATE}"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Créer le répertoire de backup
mkdir -p "${BACKUP_DIR}"

log_info "Démarrage du backup Phoenix - ${DATE}"

# 1. Backup des fichiers locaux Phoenix
log_info "Sauvegarde des fichiers Phoenix..."
if [ -d "${PHOENIX_DIR}" ]; then
    tar -czf "${BACKUP_DIR}/${BACKUP_NAME}_files.tar.gz" -C "${HOME}" .phoenix 2>/dev/null || log_warn "Certains fichiers n'ont pas pu être sauvegardés"
    log_info "Fichiers sauvegardés: ${BACKUP_DIR}/${BACKUP_NAME}_files.tar.gz"
else
    log_error "Répertoire ${PHOENIX_DIR} non trouvé"
fi

# 2. Backup des ressources Kubernetes
log_info "Sauvegarde des ressources Kubernetes..."

# Secrets (chiffrés en base64)
kubectl get secrets -n phoenix -o yaml > "${BACKUP_DIR}/${BACKUP_NAME}_secrets.yaml" 2>/dev/null || log_warn "Pas de secrets à sauvegarder"

# ConfigMaps
kubectl get configmaps -n phoenix -o yaml > "${BACKUP_DIR}/${BACKUP_NAME}_configmaps.yaml" 2>/dev/null || log_warn "Pas de configmaps à sauvegarder"

# PersistentVolumeClaims
kubectl get pvc -n phoenix -o yaml > "${BACKUP_DIR}/${BACKUP_NAME}_pvc.yaml" 2>/dev/null || log_warn "Pas de PVC à sauvegarder"

# Deployments et Services
kubectl get deployments,services,networkpolicies -n phoenix -o yaml > "${BACKUP_DIR}/${BACKUP_NAME}_k8s_resources.yaml" 2>/dev/null || log_warn "Pas de ressources K8s à sauvegarder"

log_info "Ressources Kubernetes sauvegardées"

# 3. Backup des données des PersistentVolumes
log_info "Sauvegarde des données persistantes..."

# Identifier le pod Phoenix
POD_NAME=$(kubectl get pods -n phoenix -l app=phoenix -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -n "${POD_NAME}" ]; then
    kubectl exec -n phoenix "${POD_NAME}" -- tar -czf - /data 2>/dev/null > "${BACKUP_DIR}/${BACKUP_NAME}_data.tar.gz" || log_warn "Pas de données /data à sauvegarder"
    log_info "Données persistantes sauvegardées"
else
    log_warn "Pod Phoenix non trouvé, skip backup des données"
fi

# 4. Créer un manifest de restauration
log_info "Création du manifest de restauration..."
cat << EOF > "${BACKUP_DIR}/${BACKUP_NAME}_manifest.txt"
# Manifest de backup Phoenix
# Date: ${DATE}
# Version: 1.0.0

Fichiers inclus:
- ${BACKUP_NAME}_files.tar.gz (config Phoenix)
- ${BACKUP_NAME}_secrets.yaml (Kubernetes Secrets)
- ${BACKUP_NAME}_configmaps.yaml (Kubernetes ConfigMaps)
- ${BACKUP_NAME}_pvc.yaml (PersistentVolumeClaims)
- ${BACKUP_NAME}_k8s_resources.yaml (Deployments, Services)
- ${BACKUP_NAME}_data.tar.gz (Données persistantes)

Pour restaurer:
1. tar -xzf ${BACKUP_NAME}_files.tar.gz -C \${HOME}
2. kubectl apply -f ${BACKUP_NAME}_secrets.yaml
3. kubectl apply -f ${BACKUP_NAME}_configmaps.yaml
4. kubectl apply -f ${BACKUP_NAME}_k8s_resources.yaml
EOF

log_info "Manifest créé: ${BACKUP_DIR}/${BACKUP_NAME}_manifest.txt"

# 5. Calcul de la taille et checksum
log_info "Calcul des checksums..."
cd "${BACKUP_DIR}"
sha256sum ${BACKUP_NAME}_* > "${BACKUP_NAME}_checksums.sha256"
log_info "Checksums créés: ${BACKUP_NAME}_checksums.sha256"

# Taille totale
TOTAL_SIZE=$(du -sh "${BACKUP_DIR}/${BACKUP_NAME}"* 2>/dev/null | tail -1 | cut -f1)
log_info "Taille totale du backup: ${TOTAL_SIZE}"

# 6. Nettoyage des anciens backups
log_info "Nettoyage des backups de plus de ${RETENTION_DAYS} jours..."
find "${BACKUP_DIR}" -name "phoenix_backup_*" -type f -mtime +${RETENTION_DAYS} -delete 2>/dev/null || true
log_info "Nettoyage terminé"

# 7. Résumé
log_info "========================================"
log_info "BACKUP TERMINÉ AVEC SUCCÈS"
log_info "Emplacement: ${BACKUP_DIR}"
log_info "Préfixe: ${BACKUP_NAME}"
log_info "========================================"
EOFSCRIPT

chmod +x ~/scripts/backup-phoenix.sh
```

**Vérification :**

```bash
ls -la ~/scripts/backup-phoenix.sh
```

### Étape 3 : Tester le backup manuellement

**Pourquoi ?** On ne fait JAMAIS confiance à un backup non testé.

**Comment ?**

```bash
~/scripts/backup-phoenix.sh
```

**Résultat attendu :**
```
[INFO] Démarrage du backup Phoenix - 20260202_143000
[INFO] Sauvegarde des fichiers Phoenix...
[INFO] Fichiers sauvegardés: /Users/ethan/backups/phoenix/phoenix_backup_20260202_143000_files.tar.gz
[INFO] Sauvegarde des ressources Kubernetes...
[INFO] Ressources Kubernetes sauvegardées
[INFO] BACKUP TERMINÉ AVEC SUCCÈS
```

**Vérifier les fichiers créés :**

```bash
ls -la ~/backups/phoenix/
```

### Étape 4 : Configurer le backup automatique avec cron

**Pourquoi ?** Tu ne veux pas te souvenir de lancer le backup tous les jours.

**Comment ?**

1. Ouvrir l'éditeur cron :

```bash
crontab -e
```

2. Ajouter cette ligne (backup tous les jours à 3h du matin) :

```
0 3 * * * /Users/$(whoami)/scripts/backup-phoenix.sh >> /Users/$(whoami)/backups/phoenix/cron.log 2>&1
```

**Vérification :**

```bash
crontab -l
```

### Étape 5 : Créer le script de restauration

**Pourquoi ?** Un backup sans procédure de restauration est inutile.

**Comment ?**

```bash
cat << 'EOFSCRIPT' > ~/scripts/restore-phoenix.sh
#!/bin/bash
# =============================================================================
# Script de restauration Phoenix
# Version: 1.0.0
# Auteur: Ethan Bernier
# =============================================================================

set -euo pipefail

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

BACKUP_DIR="${HOME}/backups/phoenix"

# Lister les backups disponibles
echo "Backups disponibles:"
echo "===================="
ls -1 "${BACKUP_DIR}"/*_manifest.txt 2>/dev/null | while read f; do
    basename "$f" | sed 's/_manifest.txt//'
done

echo ""
read -p "Entrez le préfixe du backup à restaurer (ex: phoenix_backup_20260202_143000): " BACKUP_PREFIX

if [ -z "${BACKUP_PREFIX}" ]; then
    log_error "Aucun backup sélectionné"
    exit 1
fi

# Vérifier que le backup existe
if [ ! -f "${BACKUP_DIR}/${BACKUP_PREFIX}_manifest.txt" ]; then
    log_error "Backup non trouvé: ${BACKUP_PREFIX}"
    exit 1
fi

log_info "Restauration du backup: ${BACKUP_PREFIX}"

# Vérifier les checksums
log_info "Vérification des checksums..."
cd "${BACKUP_DIR}"
if sha256sum -c "${BACKUP_PREFIX}_checksums.sha256"; then
    log_info "Checksums OK"
else
    log_error "Checksums invalides ! Backup potentiellement corrompu."
    read -p "Continuer quand même ? (y/N): " CONTINUE
    if [ "${CONTINUE}" != "y" ]; then
        exit 1
    fi
fi

# Confirmation
log_warn "ATTENTION: Cette opération va écraser les données actuelles !"
read -p "Êtes-vous sûr de vouloir continuer ? (y/N): " CONFIRM

if [ "${CONFIRM}" != "y" ]; then
    log_info "Restauration annulée"
    exit 0
fi

# 1. Restaurer les fichiers locaux
log_info "Restauration des fichiers Phoenix..."
if [ -f "${BACKUP_DIR}/${BACKUP_PREFIX}_files.tar.gz" ]; then
    tar -xzf "${BACKUP_DIR}/${BACKUP_PREFIX}_files.tar.gz" -C "${HOME}"
    log_info "Fichiers restaurés"
else
    log_warn "Fichier files.tar.gz non trouvé"
fi

# 2. Restaurer les ressources Kubernetes
log_info "Restauration des ressources Kubernetes..."

# Secrets
if [ -f "${BACKUP_DIR}/${BACKUP_PREFIX}_secrets.yaml" ]; then
    kubectl apply -f "${BACKUP_DIR}/${BACKUP_PREFIX}_secrets.yaml" --force
    log_info "Secrets restaurés"
fi

# ConfigMaps
if [ -f "${BACKUP_DIR}/${BACKUP_PREFIX}_configmaps.yaml" ]; then
    kubectl apply -f "${BACKUP_DIR}/${BACKUP_PREFIX}_configmaps.yaml" --force
    log_info "ConfigMaps restaurés"
fi

# Ressources K8s
if [ -f "${BACKUP_DIR}/${BACKUP_PREFIX}_k8s_resources.yaml" ]; then
    kubectl apply -f "${BACKUP_DIR}/${BACKUP_PREFIX}_k8s_resources.yaml" --force
    log_info "Ressources K8s restaurées"
fi

# 3. Redémarrer Phoenix
log_info "Redémarrage d'Phoenix..."
kubectl rollout restart deployment/phoenix -n phoenix 2>/dev/null || log_warn "Déploiement non trouvé"

# 4. Attendre que le pod soit ready
log_info "Attente du démarrage..."
kubectl wait --for=condition=ready pod -l app=phoenix -n phoenix --timeout=120s 2>/dev/null || log_warn "Timeout en attendant le pod"

log_info "========================================"
log_info "RESTAURATION TERMINÉE"
log_info "========================================"
EOFSCRIPT

chmod +x ~/scripts/restore-phoenix.sh
```

### Étape 6 : Backup vers stockage externe (optionnel)

**Pourquoi ?** Si ton Mac brûle, les backups locaux partent aussi.

**Options de stockage externe :**

| Solution | Coût | Difficulté | Sécurité |
|----------|------|------------|----------|
| iCloud | Gratuit (5Go) | ⭐ | ⭐⭐⭐ |
| Backblaze B2 | ~$5/To | ⭐⭐ | ⭐⭐⭐⭐ |
| rsync.net | ~$8/100Go | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| NAS local | Achat unique | ⭐⭐ | ⭐⭐⭐ |

**Exemple avec rclone + Backblaze B2 :**

```bash
brew install rclone && rclone config
```

Puis ajouter au script de backup :

```bash
rclone sync ~/backups/phoenix b2:mon-bucket-phoenix/backups --progress
```

### Étape 7 : Tester la restauration complète

**Pourquoi ?** Un backup qui ne peut pas être restauré est un faux sentiment de sécurité.

**Procédure de test :**

1. Créer un environnement de test :

```bash
kubectl create namespace phoenix-test
```

2. Restaurer dans l'environnement de test :

```bash
sed 's/namespace: phoenix/namespace: phoenix-test/g' ~/backups/phoenix/phoenix_backup_*_k8s_resources.yaml | kubectl apply -f -
```

3. Vérifier que tout fonctionne :

```bash
kubectl get pods -n phoenix-test
```

4. Nettoyer :

```bash
kubectl delete namespace phoenix-test
```

---

## 📊 Stratégie de backup recommandée

```
┌─────────────────────────────────────────────────────────────────┐
│                    STRATÉGIE 3-2-1                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  3 copies de tes données                                        │
│  ├── 1. Données originales (~/.phoenix)                        │
│  ├── 2. Backup local (~/backups/phoenix)                       │
│  └── 3. Backup externe (cloud ou NAS)                           │
│                                                                 │
│  2 types de supports différents                                 │
│  ├── 1. SSD Mac                                                 │
│  └── 2. Cloud ou NAS                                            │
│                                                                 │
│  1 copie hors site                                              │
│  └── Cloud (Backblaze, iCloud, etc.)                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## ✅ Checklist

- [ ] Script de backup créé et testé
- [ ] Cron configuré (backup quotidien)
- [ ] Script de restauration créé
- [ ] Checksums vérifiés
- [ ] Restauration testée dans environnement de test
- [ ] Backup externe configuré (optionnel mais recommandé)
- [ ] Documentation de la procédure de restauration

---

## ⚠️ Dépannage

**Problème :** "Le backup échoue avec 'permission denied'"

**Solution :**
```bash
chmod 700 ~/.phoenix && chmod 600 ~/.phoenix/credentials/*
```

**Problème :** "Les checksums ne correspondent pas"

**Solution :** Le fichier a été modifié ou corrompu. Utilise un backup plus ancien ou vérifie l'intégrité du stockage.

**Problème :** "La restauration échoue avec 'resource already exists'"

**Solution :**
```bash
kubectl delete -f ~/backups/phoenix/phoenix_backup_*_k8s_resources.yaml --ignore-not-found && kubectl apply -f ~/backups/phoenix/phoenix_backup_*_k8s_resources.yaml
```

---

## 🔗 Ressources

- [rclone Documentation](https://rclone.org/docs/)
- [Backblaze B2](https://www.backblaze.com/b2/cloud-storage.html)
- [Kubernetes Backup Best Practices](https://kubernetes.io/docs/concepts/cluster-administration/addons/)
- [Velero (backup K8s avancé)](https://velero.io/)

---

## ➡️ Prochaine étape

👉 [Chapitre 4.1 - Connexion aux LLM locaux](../04-utiliser/01-connexion-llm-locaux.md)

---

**🎉 Félicitations ! Tu as terminé la Partie 3 : Sécuriser**

Ton installation Phoenix est maintenant :
- ✅ Isolée dans des containers
- ✅ Protégée par un proxy whitelist
- ✅ Sécurisée avec Network Policies
- ✅ Auditée contre les vulnérabilités
- ✅ Monitorée en temps réel
- ✅ Sauvegardée automatiquement

Passons à l'utilisation !
