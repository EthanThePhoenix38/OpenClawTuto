# 🎯 Chapitre 5 - Audit Sécurité (CVE/OWASP/NIST)

## 📋 Ce que tu vas apprendre

Dans ce chapitre, tu vas mettre en place un processus d'audit de sécurité continu basé sur les référentiels CVE, OWASP et NIST. L'audit est la validation que toutes les mesures de sécurité fonctionnent correctement.

- **Pourquoi auditer ?** La sécurité se dégrade avec le temps : nouvelles vulnérabilités (CVE), mises à jour manquées, configurations qui dérivent. L'audit détecte ces problèmes avant les attaquants.
- **Référentiels utilisés** :
  - **CVE** (Common Vulnerabilities and Exposures) : Base de données des vulnérabilités connues
  - **OWASP Top 10** : Les 10 risques de sécurité les plus critiques pour les applications
  - **NIST Cybersecurity Framework** : Cadre de référence pour la gestion des risques

## 🛠️ Prérequis

- Phoenix déployé dans Kubernetes (Chapitres 1-4)
- Accès aux images Docker utilisées
- Trivy installé (scanner de vulnérabilités)

## 📝 Étapes détaillées

### Étape 1 : Installer les outils d'audit

**Pourquoi ?** Des outils spécialisés automatisent la détection des vulnérabilités. On ne peut pas tout vérifier manuellement.

**Comment ?**

Installe Trivy (scanner de vulnérabilités) :

```bash
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.48.0 2>/dev/null || echo "Trivy déjà installé ou installation manuelle requise"
```

Vérifie l'installation :

```bash
trivy version 2>/dev/null || echo "Installer Trivy: https://aquasecurity.github.io/trivy/"
```

Installe kubeaudit (audit Kubernetes) :

```bash
curl -sL https://github.com/Shopify/kubeaudit/releases/download/v0.22.0/kubeaudit_0.22.0_linux_amd64.tar.gz | tar xz -C /usr/local/bin kubeaudit 2>/dev/null || echo "kubeaudit déjà installé ou installation manuelle requise"
```

**Vérification :**

```bash
which trivy kubeaudit 2>/dev/null && echo "Outils d'audit installés" || echo "Installation manuelle requise"
```

### Étape 2 : Scanner les images Docker pour les CVE

**Pourquoi ?** Les images Docker contiennent des bibliothèques qui peuvent avoir des vulnérabilités connues (CVE). Un scan régulier les détecte.

**Comment ?**

Scanne l'image Phoenix :

```bash
trivy image --severity HIGH,CRITICAL phoenix:latest 2>/dev/null || echo "Image phoenix:latest non disponible - scanner vos vraies images"
```

Scanne l'image Squid :

```bash
trivy image --severity HIGH,CRITICAL ubuntu/squid:latest 2>/dev/null | head -50 || echo "Scanner avec: trivy image ubuntu/squid:latest"
```

Pour un rapport complet au format JSON :

```bash
trivy image --format json --output /tmp/trivy-report.json ubuntu/squid:latest 2>/dev/null && echo "Rapport généré: /tmp/trivy-report.json" || echo "Exécuter le scan manuellement"
```

**Vérification :**

```bash
cat /tmp/trivy-report.json 2>/dev/null | jq '.Results[].Vulnerabilities | length' 2>/dev/null || echo "Rapport non disponible"
```

### Étape 3 : Créer le job d'audit automatique

**Pourquoi ?** L'audit doit être automatique et régulier. Un CronJob Kubernetes exécute les scans périodiquement.

**Comment ?**

```bash
cat << 'EOF' > /tmp/security-audit-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: security-audit
  namespace: phoenix-sandbox
spec:
  schedule: "0 3 * * *"  # Tous les jours à 3h du matin
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 7
  failedJobsHistoryLimit: 3
  jobTemplate:
    spec:
      template:
        spec:
          securityContext:
            runAsNonRoot: true
            runAsUser: 1000
            runAsGroup: 1000
            seccompProfile:
              type: RuntimeDefault
          containers:
          - name: audit
            image: aquasec/trivy:latest
            securityContext:
              allowPrivilegeEscalation: false
              readOnlyRootFilesystem: true
              capabilities:
                drop:
                  - ALL
            command:
            - /bin/sh
            - -c
            - |
              echo "=== Audit de Sécurité Phoenix - $(date) ==="
              echo ""
              echo "=== 1. Scan des vulnérabilités CVE ==="

              # Liste des images à scanner
              IMAGES="ubuntu/squid:latest busybox:latest"

              for IMAGE in $IMAGES; do
                echo "Scanning: $IMAGE"
                trivy image --severity HIGH,CRITICAL --no-progress $IMAGE 2>/dev/null || echo "Erreur scan $IMAGE"
                echo "---"
              done

              echo ""
              echo "=== 2. Vérification OWASP Top 10 ==="
              echo "A01:2021 - Broken Access Control: Vérifier RBAC"
              echo "A02:2021 - Cryptographic Failures: Vérifier TLS/Secrets"
              echo "A03:2021 - Injection: Vérifier sandbox commandes"
              echo "A05:2021 - Security Misconfiguration: Vérifier policies"
              echo "A09:2021 - Security Logging: Vérifier audit logs"

              echo ""
              echo "=== 3. Checklist NIST CSF ==="
              echo "IDENTIFY: Assets inventoriés"
              echo "PROTECT: Contrôles en place"
              echo "DETECT: Monitoring actif"
              echo "RESPOND: Procédures définies"
              echo "RECOVER: Backups vérifiés"

              echo ""
              echo "=== Audit terminé ==="
            volumeMounts:
            - name: cache
              mountPath: /tmp
          volumes:
          - name: cache
            emptyDir:
              sizeLimit: 500Mi
          restartPolicy: OnFailure
EOF
```

```bash
kubectl apply -f /tmp/security-audit-cronjob.yaml
```

**Vérification :**

```bash
kubectl get cronjob security-audit -n phoenix-sandbox
```

### Étape 4 : Auditer la conformité OWASP Top 10

**Pourquoi ?** L'OWASP Top 10 liste les vulnérabilités applicatives les plus courantes. On doit vérifier que notre configuration les adresse.

**Comment ?**

Crée un script d'audit OWASP :

```bash
cat << 'EOF' > /tmp/owasp-audit.sh
#!/bin/bash
echo "=== Audit OWASP Top 10 2021 pour Phoenix ==="
echo ""

NAMESPACE="phoenix-sandbox"
SCORE=0
TOTAL=10

# A01:2021 - Broken Access Control
echo "A01:2021 - Broken Access Control"
RBAC_COUNT=$(kubectl get role,rolebinding -n $NAMESPACE --no-headers 2>/dev/null | wc -l)
if [ "$RBAC_COUNT" -gt 0 ]; then
  echo "  [OK] RBAC configuré ($RBAC_COUNT règles)"
  SCORE=$((SCORE+1))
else
  echo "  [FAIL] RBAC non configuré"
fi

# A02:2021 - Cryptographic Failures
echo "A02:2021 - Cryptographic Failures"
SECRETS_COUNT=$(kubectl get secrets -n $NAMESPACE -l app=phoenix --no-headers 2>/dev/null | wc -l)
if [ "$SECRETS_COUNT" -gt 0 ]; then
  echo "  [OK] Secrets Kubernetes utilisés ($SECRETS_COUNT)"
  SCORE=$((SCORE+1))
else
  echo "  [WARN] Vérifier l'utilisation des secrets"
fi

# A03:2021 - Injection
echo "A03:2021 - Injection"
SANDBOX_CONFIG=$(kubectl get configmap phoenix-config -n $NAMESPACE -o jsonpath='{.data.sandbox\.yaml}' 2>/dev/null | grep -c "blocked_commands")
if [ "$SANDBOX_CONFIG" -gt 0 ]; then
  echo "  [OK] Sandbox avec commandes bloquées configuré"
  SCORE=$((SCORE+1))
else
  echo "  [FAIL] Sandbox non configuré"
fi

# A04:2021 - Insecure Design
echo "A04:2021 - Insecure Design"
NETPOL_COUNT=$(kubectl get networkpolicy -n $NAMESPACE --no-headers 2>/dev/null | wc -l)
if [ "$NETPOL_COUNT" -ge 3 ]; then
  echo "  [OK] Network Policies en place ($NETPOL_COUNT)"
  SCORE=$((SCORE+1))
else
  echo "  [FAIL] Network Policies insuffisantes"
fi

# A05:2021 - Security Misconfiguration
echo "A05:2021 - Security Misconfiguration"
PSS_LABEL=$(kubectl get namespace $NAMESPACE -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null)
if [ "$PSS_LABEL" = "restricted" ]; then
  echo "  [OK] Pod Security Standards: restricted"
  SCORE=$((SCORE+1))
else
  echo "  [FAIL] Pod Security Standards non configuré"
fi

# A06:2021 - Vulnerable and Outdated Components
echo "A06:2021 - Vulnerable and Outdated Components"
echo "  [INFO] Exécuter: trivy image <votre-image>"
SCORE=$((SCORE+1))

# A07:2021 - Identification and Authentication Failures
echo "A07:2021 - Identification and Authentication Failures"
SA_TOKEN=$(kubectl get pod -n $NAMESPACE -o jsonpath='{.items[0].spec.automountServiceAccountToken}' 2>/dev/null)
if [ "$SA_TOKEN" = "false" ]; then
  echo "  [OK] ServiceAccount token non monté automatiquement"
  SCORE=$((SCORE+1))
else
  echo "  [WARN] Vérifier automountServiceAccountToken"
fi

# A08:2021 - Software and Data Integrity Failures
echo "A08:2021 - Software and Data Integrity Failures"
PULL_POLICY=$(kubectl get pod -n $NAMESPACE -o jsonpath='{.items[0].spec.containers[0].imagePullPolicy}' 2>/dev/null)
if [ "$PULL_POLICY" = "IfNotPresent" ] || [ "$PULL_POLICY" = "Never" ]; then
  echo "  [OK] Image pull policy: $PULL_POLICY"
  SCORE=$((SCORE+1))
else
  echo "  [WARN] Utiliser des images avec tags fixes"
fi

# A09:2021 - Security Logging and Monitoring Failures
echo "A09:2021 - Security Logging and Monitoring Failures"
SQUID_LOGS=$(kubectl exec deployment/squid-proxy -n $NAMESPACE -- ls /var/log/squid/ 2>/dev/null | wc -l)
if [ "$SQUID_LOGS" -gt 0 ]; then
  echo "  [OK] Logs Squid actifs"
  SCORE=$((SCORE+1))
else
  echo "  [WARN] Vérifier les logs"
fi

# A10:2021 - Server-Side Request Forgery (SSRF)
echo "A10:2021 - Server-Side Request Forgery (SSRF)"
PROXY_REQUIRED=$(kubectl get configmap phoenix-config -n $NAMESPACE -o jsonpath='{.data.sandbox\.yaml}' 2>/dev/null | grep -c "proxy_required: true")
if [ "$PROXY_REQUIRED" -gt 0 ]; then
  echo "  [OK] Proxy obligatoire (protection SSRF)"
  SCORE=$((SCORE+1))
else
  echo "  [FAIL] Proxy non obligatoire"
fi

echo ""
echo "=== Score OWASP: $SCORE/$TOTAL ==="
if [ "$SCORE" -ge 8 ]; then
  echo "Statut: BON"
elif [ "$SCORE" -ge 5 ]; then
  echo "Statut: À AMÉLIORER"
else
  echo "Statut: CRITIQUE - Actions requises"
fi
EOF
chmod +x /tmp/owasp-audit.sh
```

Exécute l'audit :

```bash
/tmp/owasp-audit.sh
```

**Vérification :**

Le score doit être d'au moins 8/10 pour un niveau de sécurité acceptable.

### Étape 5 : Auditer la conformité NIST CSF

**Pourquoi ?** Le NIST Cybersecurity Framework fournit un cadre complet pour évaluer la posture de sécurité. Il couvre 5 fonctions : Identify, Protect, Detect, Respond, Recover.

**Comment ?**

```bash
cat << 'EOF' > /tmp/nist-audit.sh
#!/bin/bash
echo "=== Audit NIST Cybersecurity Framework ==="
echo ""
NAMESPACE="phoenix-sandbox"

echo "== 1. IDENTIFY (ID) =="
echo "ID.AM - Asset Management"
echo "  Pods: $(kubectl get pods -n $NAMESPACE --no-headers 2>/dev/null | wc -l)"
echo "  Services: $(kubectl get services -n $NAMESPACE --no-headers 2>/dev/null | wc -l)"
echo "  Secrets: $(kubectl get secrets -n $NAMESPACE --no-headers 2>/dev/null | wc -l)"
echo "  ConfigMaps: $(kubectl get configmaps -n $NAMESPACE --no-headers 2>/dev/null | wc -l)"

echo ""
echo "== 2. PROTECT (PR) =="
echo "PR.AC - Access Control"
kubectl get role,rolebinding -n $NAMESPACE --no-headers 2>/dev/null | wc -l | xargs -I {} echo "  Règles RBAC: {}"
echo "PR.DS - Data Security"
kubectl get secrets -n $NAMESPACE --no-headers 2>/dev/null | wc -l | xargs -I {} echo "  Secrets protégés: {}"
echo "PR.IP - Information Protection"
kubectl get networkpolicy -n $NAMESPACE --no-headers 2>/dev/null | wc -l | xargs -I {} echo "  Network Policies: {}"
echo "PR.PT - Protective Technology"
kubectl get pod -n $NAMESPACE -l app=squid-proxy --no-headers 2>/dev/null | wc -l | xargs -I {} echo "  Proxy actif: {}"

echo ""
echo "== 3. DETECT (DE) =="
echo "DE.CM - Security Continuous Monitoring"
kubectl get cronjob -n $NAMESPACE --no-headers 2>/dev/null | wc -l | xargs -I {} echo "  CronJobs monitoring: {}"
echo "DE.AE - Anomalies and Events"
echo "  Vérifier les logs Squid pour anomalies"

echo ""
echo "== 4. RESPOND (RS) =="
echo "RS.RP - Response Planning"
echo "  Documentation: Vérifier /docs/incident-response.md"
echo "RS.CO - Communications"
echo "  Alertes configurées: Vérifier monitoring"

echo ""
echo "== 5. RECOVER (RC) =="
echo "RC.RP - Recovery Planning"
kubectl get cronjob -n $NAMESPACE -l function=backup --no-headers 2>/dev/null | wc -l | xargs -I {} echo "  Jobs de backup: {}"
echo "RC.IM - Improvements"
echo "  Revue post-incident: Documenter les leçons apprises"

echo ""
echo "=== Audit NIST terminé ==="
EOF
chmod +x /tmp/nist-audit.sh && /tmp/nist-audit.sh
```

**Vérification :**

```bash
echo "Résumé NIST CSF:" && kubectl get pods,services,secrets,configmaps,networkpolicy,cronjob -n phoenix-sandbox --no-headers 2>/dev/null | wc -l | xargs -I {} echo "Total ressources auditées: {}"
```

### Étape 6 : Auditer les configurations Kubernetes avec kubeaudit

**Pourquoi ?** kubeaudit vérifie automatiquement les bonnes pratiques de sécurité Kubernetes.

**Comment ?**

Audit du namespace :

```bash
kubeaudit all -n phoenix-sandbox 2>/dev/null || echo "Exécuter: kubeaudit all -n phoenix-sandbox"
```

Pour un audit spécifique :

```bash
kubeaudit nonroot -n phoenix-sandbox 2>/dev/null && echo "Audit nonroot OK" || echo "Exécuter manuellement"
```

```bash
kubeaudit privesc -n phoenix-sandbox 2>/dev/null && echo "Audit privilege escalation OK" || echo "Exécuter manuellement"
```

```bash
kubeaudit rootfs -n phoenix-sandbox 2>/dev/null && echo "Audit rootfs OK" || echo "Exécuter manuellement"
```

**Vérification :**

```bash
echo "Pour un audit complet, exécuter: kubeaudit all -n phoenix-sandbox -f json > /tmp/kubeaudit-report.json"
```

### Étape 7 : Créer le rapport d'audit consolidé

**Pourquoi ?** Un rapport consolidé permet de suivre l'évolution de la posture de sécurité dans le temps et de communiquer avec les parties prenantes.

**Comment ?**

```bash
cat << 'EOF' > /tmp/generate-audit-report.sh
#!/bin/bash
NAMESPACE="phoenix-sandbox"
DATE=$(date +%Y-%m-%d)
REPORT_FILE="/tmp/security-audit-report-$DATE.md"

cat > $REPORT_FILE << REPORT
# Rapport d'Audit Sécurité Phoenix
Date: $DATE
Namespace: $NAMESPACE

## Résumé Exécutif

Ce rapport présente l'état de sécurité du déploiement Phoenix.

## 1. Inventaire des Assets

| Type | Nombre |
|------|--------|
| Pods | $(kubectl get pods -n $NAMESPACE --no-headers 2>/dev/null | wc -l) |
| Services | $(kubectl get services -n $NAMESPACE --no-headers 2>/dev/null | wc -l) |
| Secrets | $(kubectl get secrets -n $NAMESPACE --no-headers 2>/dev/null | wc -l) |
| ConfigMaps | $(kubectl get configmaps -n $NAMESPACE --no-headers 2>/dev/null | wc -l) |
| Network Policies | $(kubectl get networkpolicy -n $NAMESPACE --no-headers 2>/dev/null | wc -l) |

## 2. Contrôles de Sécurité

### 2.1 Pod Security Standards
$(kubectl get namespace $NAMESPACE -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null || echo "Non configuré")

### 2.2 RBAC
$(kubectl get role,rolebinding -n $NAMESPACE --no-headers 2>/dev/null | wc -l) règles configurées

### 2.3 Network Policies
$(kubectl get networkpolicy -n $NAMESPACE -o name 2>/dev/null | tr '\n' ', ' || echo "Aucune")

## 3. Vulnérabilités Connues (CVE)

Exécuter: trivy image <images-utilisées>

## 4. Conformité

### 4.1 OWASP Top 10
- [ ] A01 - Broken Access Control
- [ ] A02 - Cryptographic Failures
- [ ] A03 - Injection
- [ ] A04 - Insecure Design
- [ ] A05 - Security Misconfiguration
- [ ] A06 - Vulnerable Components
- [ ] A07 - Authentication Failures
- [ ] A08 - Integrity Failures
- [ ] A09 - Logging Failures
- [ ] A10 - SSRF

### 4.2 NIST CSF
- [ ] Identify
- [ ] Protect
- [ ] Detect
- [ ] Respond
- [ ] Recover

## 5. Recommandations

1. [À compléter après revue]
2. [À compléter après revue]
3. [À compléter après revue]

## 6. Prochaines Actions

| Action | Priorité | Responsable | Échéance |
|--------|----------|-------------|----------|
| | | | |

---
Généré automatiquement par le script d'audit Phoenix
REPORT

echo "Rapport généré: $REPORT_FILE"
cat $REPORT_FILE
EOF
chmod +x /tmp/generate-audit-report.sh && /tmp/generate-audit-report.sh
```

**Vérification :**

```bash
ls -la /tmp/security-audit-report-*.md 2>/dev/null || echo "Générer le rapport avec /tmp/generate-audit-report.sh"
```

## ✅ Checklist

Avant de passer au chapitre suivant, vérifie que :

- [ ] Trivy installé et fonctionnel
- [ ] CronJob d'audit automatique configuré
- [ ] Script d'audit OWASP Top 10 créé et exécuté
- [ ] Script d'audit NIST CSF créé et exécuté
- [ ] Rapport d'audit consolidé généré
- [ ] Score OWASP >= 8/10

```bash
echo "=== Vérification Audit ===" && kubectl get cronjob security-audit -n phoenix-sandbox 2>/dev/null && ls -la /tmp/*-audit*.sh 2>/dev/null && echo "=== Audit OK ==="
```

## ⚠️ Dépannage

### Erreur : "trivy: command not found"

**Cause** : Trivy n'est pas installé ou pas dans le PATH.

**Solution** :

```bash
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
```

### Erreur : "Unable to pull image"

**Cause** : Trivy ne peut pas télécharger la base de données de vulnérabilités.

**Solution** :

```bash
trivy image --download-db-only
```

### Le CronJob ne s'exécute jamais

**Cause** : Le schedule est incorrect ou le cluster n'a pas assez de ressources.

**Solution** :

```bash
kubectl describe cronjob security-audit -n phoenix-sandbox && kubectl get events -n phoenix-sandbox --field-selector involvedObject.kind=CronJob
```

### Score OWASP trop bas

**Cause** : Des contrôles de sécurité manquent.

**Solution** : Revois les chapitres précédents et assure-toi que chaque contrôle est correctement implémenté.

## 🔗 Ressources

- **CVE Database** : Base de données des vulnérabilités
  - https://cve.mitre.org/
- **OWASP Top 10 2021** : Guide complet
  - https://owasp.org/Top10/
- **NIST Cybersecurity Framework** : Documentation officielle
  - https://www.nist.gov/cyberframework
- **CWE/SANS Top 25** : Faiblesses logicielles les plus dangereuses
  - https://cwe.mitre.org/top25/
- **Trivy** : Scanner de vulnérabilités
  - https://aquasecurity.github.io/trivy/
- **kubeaudit** : Audit de sécurité Kubernetes
  - https://github.com/Shopify/kubeaudit

## ➡️ Prochaine étape

L'audit de sécurité est maintenant automatisé. Mais pour détecter les problèmes en temps réel, il faut un système de **monitoring et d'alertes** qui surveille en permanence l'état du système.

Rendez-vous au [Chapitre 6 - Monitoring et Alertes](06-monitoring-alertes.md).
