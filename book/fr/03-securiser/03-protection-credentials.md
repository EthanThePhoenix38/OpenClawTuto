# 🎯 Chapitre 3 - Protection des Credentials (Kubernetes Secrets)

## 📋 Ce que tu vas apprendre

Dans ce chapitre, tu vas sécuriser tous les secrets (API keys, tokens, mots de passe) utilisés par Phoenix. Les credentials mal protégés sont la cause principale des compromissions de sécurité.

- **Pourquoi protéger les secrets ?** Un token API exposé peut donner accès à des ressources cloud, des données sensibles, ou permettre des actions non autorisées au nom de l'utilisateur.
- **Principe du moindre privilège** : Phoenix ne doit accéder qu'aux secrets strictement nécessaires, avec des permissions minimales.
- **Defense in Depth** : Chiffrement au repos, en transit, et contrôle d'accès strict.

## 🛠️ Prérequis

- Namespace `phoenix-sandbox` configuré (Chapitre 1)
- Proxy Squid opérationnel (Chapitre 2)
- Compréhension des Secrets Kubernetes

## 📝 Étapes détaillées

### Étape 1 : Comprendre les types de secrets Phoenix

**Pourquoi ?** Avant de sécuriser, il faut identifier et classifier tous les secrets utilisés par Phoenix.

**Comment ?**

Classification des secrets par criticité :

| Secret | Criticité | Usage | Rotation |
|--------|-----------|-------|----------|
| API Key LLM (Anthropic/OpenAI) | CRITIQUE | Accès au modèle IA | 90 jours |
| Token GitHub | HAUTE | Accès repos code | 30 jours |
| Credentials base de données | HAUTE | Stockage données | 90 jours |
| Clés de chiffrement | CRITIQUE | Protection données | 365 jours |
| Tokens webhook | MOYENNE | Intégrations | 90 jours |

**Règle d'or** : Les secrets CRITIQUES ne doivent JAMAIS être accessibles directement par Phoenix. Utilise un service intermédiaire.

**Vérification :**

Liste les secrets existants dans le namespace :

```bash
kubectl get secrets -n phoenix-sandbox 2>/dev/null || echo "Namespace prêt pour les secrets"
```

### Étape 2 : Créer les Secrets Kubernetes chiffrés

**Pourquoi ?** Les Secrets Kubernetes sont encodés en base64 par défaut (pas chiffré !). On doit s'assurer que le chiffrement at-rest est activé.

**Comment ?**

D'abord, vérifie que le chiffrement at-rest est configuré (dépend de ton cluster) :

```bash
kubectl get pods -n kube-system -l component=kube-apiserver -o jsonpath='{.items[0].spec.containers[0].command}' 2>/dev/null | tr ' ' '\n' | grep encryption || echo "Vérifier la configuration du cluster pour le chiffrement"
```

Crée le Secret pour l'API LLM (remplace les valeurs par des placeholders) :

```bash
cat << 'EOF' > /tmp/phoenix-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: phoenix-llm-credentials
  namespace: phoenix-sandbox
  labels:
    app: phoenix
    secret-type: llm-api
    rotation-period: "90d"
type: Opaque
stringData:
  # ATTENTION: Remplacer par vos vraies clés
  # Ne JAMAIS commiter ce fichier avec des vraies valeurs
  ANTHROPIC_API_KEY: "sk-ant-PLACEHOLDER-DO-NOT-USE"
  LLM_PROVIDER: "anthropic"
  LLM_MODEL: "claude-3-opus-20240229"
  # Limite de tokens pour la sécurité
  LLM_MAX_TOKENS: "4096"
  LLM_TEMPERATURE: "0.7"
---
apiVersion: v1
kind: Secret
metadata:
  name: phoenix-github-token
  namespace: phoenix-sandbox
  labels:
    app: phoenix
    secret-type: github
    rotation-period: "30d"
type: Opaque
stringData:
  # Token avec permissions minimales : repo:read uniquement
  GITHUB_TOKEN: "ghp_PLACEHOLDER-DO-NOT-USE"
  GITHUB_ALLOWED_ORGS: "mon-organisation"
---
apiVersion: v1
kind: Secret
metadata:
  name: phoenix-internal-keys
  namespace: phoenix-sandbox
  labels:
    app: phoenix
    secret-type: internal
    rotation-period: "365d"
type: Opaque
stringData:
  # Clé de chiffrement pour les données locales
  ENCRYPTION_KEY: "PLACEHOLDER-32-BYTES-KEY-HERE!!"
  # Secret pour les sessions
  SESSION_SECRET: "PLACEHOLDER-SESSION-SECRET-HERE"
EOF
```

**IMPORTANT** : Ne jamais appliquer ce fichier directement. Utilise la méthode sécurisée ci-dessous.

Méthode sécurisée pour créer les secrets (sans fichier YAML avec les valeurs) :

```bash
kubectl create secret generic phoenix-llm-credentials -n phoenix-sandbox --from-literal=ANTHROPIC_API_KEY="VOTRE-VRAIE-CLE" --from-literal=LLM_PROVIDER="anthropic" --from-literal=LLM_MODEL="claude-3-opus-20240229" --from-literal=LLM_MAX_TOKENS="4096" --dry-run=client -o yaml | kubectl apply -f -
```

**Vérification :**

```bash
kubectl get secrets -n phoenix-sandbox -l app=phoenix && kubectl get secret phoenix-llm-credentials -n phoenix-sandbox -o jsonpath='{.data}' | jq -r 'keys[]'
```

### Étape 3 : Configurer RBAC pour l'accès aux secrets

**Pourquoi ?** Même dans le même namespace, l'accès aux secrets doit être explicitement autorisé. On limite l'accès au strict minimum.

**Comment ?**

```bash
cat << 'EOF' > /tmp/secret-rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: phoenix-secret-reader
  namespace: phoenix-sandbox
rules:
# Accès en lecture UNIQUEMENT aux secrets spécifiques
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames:
    - "phoenix-llm-credentials"
    - "phoenix-internal-keys"
  verbs: ["get"]
# PAS d'accès à phoenix-github-token depuis Phoenix directement
# Le token GitHub est utilisé par un service intermédiaire
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: phoenix-secret-reader-binding
  namespace: phoenix-sandbox
subjects:
- kind: ServiceAccount
  name: phoenix-restricted
  namespace: phoenix-sandbox
roleRef:
  kind: Role
  name: phoenix-secret-reader
  apiGroup: rbac.authorization.k8s.io
EOF
```

```bash
kubectl apply -f /tmp/secret-rbac.yaml
```

**Vérification :**

```bash
kubectl auth can-i get secrets/phoenix-llm-credentials -n phoenix-sandbox --as=system:serviceaccount:phoenix-sandbox:phoenix-restricted && kubectl auth can-i get secrets/phoenix-github-token -n phoenix-sandbox --as=system:serviceaccount:phoenix-sandbox:phoenix-restricted
```

La première commande doit retourner `yes`, la seconde `no`.

### Étape 4 : Monter les secrets dans le Pod Phoenix

**Pourquoi ?** Il y a deux méthodes pour exposer les secrets : variables d'environnement ou fichiers. Les fichiers sont plus sécurisés car ils ne sont pas visibles dans les logs de processus.

**Comment ?**

Mise à jour du Pod Phoenix pour utiliser les secrets :

```bash
cat << 'EOF' > /tmp/phoenix-pod-with-secrets.yaml
apiVersion: v1
kind: Pod
metadata:
  name: phoenix-agent
  namespace: phoenix-sandbox
  labels:
    app: phoenix
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: phoenix
    image: phoenix:latest
    imagePullPolicy: IfNotPresent
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
          - ALL
    # Variables d'environnement NON-SENSIBLES uniquement
    env:
    - name: LLM_PROVIDER
      valueFrom:
        secretKeyRef:
          name: phoenix-llm-credentials
          key: LLM_PROVIDER
    - name: LLM_MODEL
      valueFrom:
        secretKeyRef:
          name: phoenix-llm-credentials
          key: LLM_MODEL
    - name: LLM_MAX_TOKENS
      valueFrom:
        secretKeyRef:
          name: phoenix-llm-credentials
          key: LLM_MAX_TOKENS
    # Proxy configuration
    envFrom:
    - configMapRef:
        name: phoenix-env
    volumeMounts:
    # Secrets montés en fichiers (plus sécurisé)
    - name: llm-credentials
      mountPath: /secrets/llm
      readOnly: true
    - name: internal-keys
      mountPath: /secrets/internal
      readOnly: true
    # Volumes de travail
    - name: tmp-volume
      mountPath: /tmp
    - name: workspace
      mountPath: /workspace
    - name: config
      mountPath: /app/config
      readOnly: true
    resources:
      limits:
        memory: "2Gi"
        cpu: "2"
      requests:
        memory: "512Mi"
        cpu: "500m"
  volumes:
  # Secrets en tant que fichiers
  - name: llm-credentials
    secret:
      secretName: phoenix-llm-credentials
      items:
      - key: ANTHROPIC_API_KEY
        path: api_key
        mode: 0400
  - name: internal-keys
    secret:
      secretName: phoenix-internal-keys
      defaultMode: 0400
  # Volumes de travail
  - name: tmp-volume
    emptyDir:
      sizeLimit: 500Mi
  - name: workspace
    emptyDir:
      sizeLimit: 1Gi
  - name: config
    configMap:
      name: phoenix-config
  serviceAccountName: phoenix-restricted
  automountServiceAccountToken: false
EOF
```

**Vérification :**

```bash
kubectl apply --dry-run=client -f /tmp/phoenix-pod-with-secrets.yaml && echo "Configuration valide"
```

### Étape 5 : Implémenter la rotation automatique des secrets

**Pourquoi ?** Les secrets doivent être régulièrement renouvelés pour limiter l'impact d'une compromission. La rotation doit être automatisée pour éviter les oublis.

**Comment ?**

Crée un CronJob pour vérifier l'âge des secrets :

```bash
cat << 'EOF' > /tmp/secret-rotation-checker.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: secret-rotation-checker
  namespace: phoenix-sandbox
spec:
  schedule: "0 9 * * 1"  # Tous les lundis à 9h
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
          - name: checker
            image: bitnami/kubectl:latest
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
              echo "=== Vérification de l'âge des secrets ==="
              SECRETS=$(kubectl get secrets -n phoenix-sandbox -l app=phoenix -o jsonpath='{range .items[*]}{.metadata.name},{.metadata.creationTimestamp},{.metadata.labels.rotation-period}{"\n"}{end}')
              echo "$SECRETS" | while IFS=',' read -r name created rotation; do
                if [ -n "$name" ]; then
                  created_ts=$(date -d "$created" +%s 2>/dev/null || echo "0")
                  now_ts=$(date +%s)
                  age_days=$(( (now_ts - created_ts) / 86400 ))
                  echo "Secret: $name | Age: ${age_days} jours | Rotation: $rotation"
                  # Alerte si > 80% de la période de rotation
                  rotation_days=$(echo "$rotation" | tr -dc '0-9')
                  if [ -n "$rotation_days" ] && [ "$age_days" -gt "$((rotation_days * 80 / 100))" ]; then
                    echo "ALERTE: $name nécessite une rotation prochaine!"
                  fi
                fi
              done
          restartPolicy: OnFailure
          serviceAccountName: secret-checker
EOF
```

Crée le ServiceAccount pour le checker :

```bash
cat << 'EOF' > /tmp/secret-checker-sa.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: secret-checker
  namespace: phoenix-sandbox
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-checker-role
  namespace: phoenix-sandbox
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: secret-checker-binding
  namespace: phoenix-sandbox
subjects:
- kind: ServiceAccount
  name: secret-checker
  namespace: phoenix-sandbox
roleRef:
  kind: Role
  name: secret-checker-role
  apiGroup: rbac.authorization.k8s.io
EOF
```

```bash
kubectl apply -f /tmp/secret-checker-sa.yaml && kubectl apply -f /tmp/secret-rotation-checker.yaml
```

**Vérification :**

```bash
kubectl get cronjob secret-rotation-checker -n phoenix-sandbox
```

### Étape 6 : Protéger les secrets sensibles du Mac

**Pourquoi ?** Certains secrets du Mac (clés SSH, tokens système) ne doivent JAMAIS être accessibles depuis Phoenix, même indirectement.

**Comment ?**

Vérifie que les chemins sensibles ne sont pas montés :

```bash
cat << 'EOF' > /tmp/verify-no-sensitive-mounts.sh
#!/bin/bash
echo "=== Vérification des montages sensibles ==="
SENSITIVE_PATHS="/.ssh /etc/passwd /etc/shadow /.aws /.kube /.gnupg /.netrc"
PODS=$(kubectl get pods -n phoenix-sandbox -o jsonpath='{.items[*].metadata.name}')
for pod in $PODS; do
  echo "Vérification du pod: $pod"
  MOUNTS=$(kubectl get pod $pod -n phoenix-sandbox -o jsonpath='{.spec.volumes[*].hostPath.path}' 2>/dev/null)
  for sensitive in $SENSITIVE_PATHS; do
    if echo "$MOUNTS" | grep -q "$sensitive"; then
      echo "ALERTE CRITIQUE: $pod monte $sensitive !"
      exit 1
    fi
  done
  echo "OK: Aucun chemin sensible monté"
done
echo "=== Vérification terminée ==="
EOF
chmod +x /tmp/verify-no-sensitive-mounts.sh && /tmp/verify-no-sensitive-mounts.sh
```

**Vérification :**

```bash
kubectl get pods -n phoenix-sandbox -o jsonpath='{range .items[*]}{.metadata.name}: {.spec.volumes[*].name}{"\n"}{end}'
```

### Étape 7 : Auditer l'accès aux secrets

**Pourquoi ?** Tu dois pouvoir tracer qui accède à quels secrets et quand. C'est requis pour la conformité et la détection d'incidents.

**Comment ?**

Active l'audit Kubernetes pour les secrets (nécessite accès admin au cluster) :

```bash
cat << 'EOF' > /tmp/audit-policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
# Audit tous les accès aux secrets dans phoenix-sandbox
- level: RequestResponse
  namespaces: ["phoenix-sandbox"]
  resources:
  - group: ""
    resources: ["secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
# Audit les tentatives d'accès refusées
- level: Metadata
  namespaces: ["phoenix-sandbox"]
  omitStages:
  - RequestReceived
EOF
```

Pour les clusters locaux (kind, minikube), l'audit peut ne pas être activé par défaut. Vérifie la documentation de ton cluster.

**Vérification :**

Simule un accès et vérifie les logs :

```bash
kubectl get secret phoenix-llm-credentials -n phoenix-sandbox -o jsonpath='{.metadata.name}' && echo " - Accès réussi (vérifier les logs d'audit)"
```

## ✅ Checklist

Avant de passer au chapitre suivant, vérifie que :

- [ ] Secrets créés avec la méthode sécurisée (pas de fichier YAML avec valeurs)
- [ ] RBAC configuré pour limiter l'accès aux secrets spécifiques
- [ ] Secrets montés en fichiers (pas en variables d'environnement pour les clés API)
- [ ] CronJob de vérification de rotation configuré
- [ ] Aucun chemin sensible du Mac n'est monté dans les Pods
- [ ] ServiceAccount Phoenix ne peut PAS accéder au token GitHub directement

```bash
echo "=== Vérification Secrets ===" && kubectl get secrets -n phoenix-sandbox -l app=phoenix && kubectl get role,rolebinding -n phoenix-sandbox | grep secret && kubectl auth can-i get secrets/phoenix-github-token -n phoenix-sandbox --as=system:serviceaccount:phoenix-sandbox:phoenix-restricted && echo "=== Secrets OK ==="
```

## ⚠️ Dépannage

### Erreur : "secrets is forbidden"

**Cause** : Le ServiceAccount n'a pas les permissions RBAC pour accéder au secret.

**Solution** :

```bash
kubectl describe rolebinding -n phoenix-sandbox | grep -A5 "phoenix-restricted"
```

### Erreur : "secret not found" dans le Pod

**Cause** : Le nom du secret ou de la clé est incorrect.

**Solution** :

```bash
kubectl get secret <nom-secret> -n phoenix-sandbox -o jsonpath='{.data}' | jq 'keys'
```

### Les secrets apparaissent dans les logs

**Cause** : Les secrets sont passés en variables d'environnement et affichés par l'application.

**Solution** : Monte les secrets en fichiers et modifie l'application pour les lire depuis `/secrets/`.

### Le CronJob de rotation ne s'exécute pas

**Cause** : Le ServiceAccount n'a pas les permissions ou le schedule est incorrect.

**Solution** :

```bash
kubectl describe cronjob secret-rotation-checker -n phoenix-sandbox && kubectl get events -n phoenix-sandbox --field-selector involvedObject.name=secret-rotation-checker
```

### Un secret a été compromis

**Procédure d'urgence** :

1. Révoquer immédiatement le secret côté fournisseur (API provider, GitHub, etc.)
2. Supprimer le secret Kubernetes : `kubectl delete secret <nom> -n phoenix-sandbox`
3. Créer un nouveau secret avec une nouvelle valeur
4. Redémarrer les Pods : `kubectl rollout restart deployment -n phoenix-sandbox`
5. Analyser les logs d'audit pour comprendre la compromission

## 🔗 Ressources

- **Kubernetes Secrets** : Documentation officielle
  - https://kubernetes.io/docs/concepts/configuration/secret/
- **OWASP Secrets Management** : Bonnes pratiques
  - https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html
- **CIS Kubernetes Benchmark** : Section 5.4 (Secrets Management)
  - https://www.cisecurity.org/benchmark/kubernetes
- **NIST SP 800-57** : Recommendation for Key Management
  - https://csrc.nist.gov/publications/detail/sp/800-57-part-1/rev-5/final

## ➡️ Prochaine étape

Les secrets sont maintenant protégés avec des contrôles d'accès stricts. Mais la sécurité réseau n'est pas complète sans **Network Policies** qui contrôlent les flux de trafic au niveau du cluster.

Rendez-vous au [Chapitre 4 - Network Policies](04-network-policies.md).
